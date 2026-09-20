//! Interactive audit dashboard and selective apply workflow.

mod state;
mod theme;

use std::{
    io::{self, Write},
    time::Duration,
};

use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use ratatui::{
    Frame, Terminal,
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Wrap},
};

use crate::{cli::FilterArgs, console::Console, engine::Engine};
use state::App;

/// Opens the terminal dashboard for the selected resource identifiers.
///
/// Terminal state is restored before returning, including after event-loop
/// failures.
///
/// # Errors
///
/// Returns an error when terminal setup, drawing, input, auditing, or applying
/// fails.
pub fn run(engine: &Engine, ids: Vec<String>, console: Console) -> Result<()> {
    tracing::info!(resource_count = ids.len(), "TUI session starting");
    let mut terminal = start_terminal()?;
    let mut app = App::new(engine.audit_ids(&ids));
    let result = event_loop(&mut terminal, engine, &ids, &mut app, &console);
    stop_terminal(&mut terminal)?;
    tracing::info!("TUI session ended");
    result
}

fn event_loop(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    engine: &Engine,
    ids: &[String],
    app: &mut App,
    console: &Console,
) -> Result<()> {
    loop {
        terminal.draw(|frame| render(frame, app))?;
        if !event::poll(Duration::from_millis(250))? {
            continue;
        }

        let Event::Key(key) = event::read()? else {
            continue;
        };
        if key.kind != KeyEventKind::Press {
            continue;
        }

        if app.confirming {
            match key.code {
                KeyCode::Char('y') | KeyCode::Enter => {
                    app.confirming = false;
                    apply_selected(terminal, engine, ids, app, console)?;
                }
                KeyCode::Char('n') | KeyCode::Esc => app.confirming = false,
                _ => {}
            }
            continue;
        }

        if app.searching {
            match key.code {
                KeyCode::Enter => app.searching = false,
                KeyCode::Esc => {
                    app.searching = false;
                    app.query.clear();
                    app.clamp_cursor();
                }
                KeyCode::Backspace => {
                    app.query.pop();
                    app.clamp_cursor();
                }
                KeyCode::Char(character) => {
                    app.query.push(character);
                    app.clamp_cursor();
                }
                _ => {}
            }
            continue;
        }

        match key.code {
            KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
            KeyCode::Char('j') | KeyCode::Down => {
                let length = app.visible().len();
                if length > 0 {
                    app.cursor = (app.cursor + 1).min(length - 1);
                }
            }
            KeyCode::Char('k') | KeyCode::Up => {
                app.cursor = app.cursor.saturating_sub(1);
            }
            KeyCode::Char('g') | KeyCode::Home => app.cursor = 0,
            KeyCode::Char('G') | KeyCode::End => {
                app.cursor = app.visible().len().saturating_sub(1);
            }
            KeyCode::Char(' ') => {
                if let Some(result) = app.current() {
                    let id = result.id.clone();
                    if result.fixable && !result.status.is_healthy() && !app.selected.remove(&id) {
                        app.selected.insert(id);
                    }
                }
            }
            KeyCode::Char('a') => {
                app.selected = app
                    .results
                    .iter()
                    .filter(|result| !result.status.is_healthy() && result.fixable)
                    .map(|result| result.id.clone())
                    .collect();
            }
            KeyCode::Char('n') => app.selected.clear(),
            KeyCode::Char('i') => {
                app.show_healthy = !app.show_healthy;
                app.clamp_cursor();
            }
            KeyCode::Char('r') => {
                tracing::debug!("TUI audit refresh requested");
                app.results = engine.audit_ids(ids);
                app.clamp_cursor();
                app.message = "Audit refreshed".to_owned();
            }
            KeyCode::Char('/') => {
                app.searching = true;
                app.message = "Type to filter; Enter accepts, Esc clears".to_owned();
            }
            KeyCode::Enter => {
                if app.selected.is_empty() {
                    app.message = "Select at least one fixable resource".to_owned();
                } else {
                    tracing::info!(
                        selected_count = app.selected.len(),
                        "TUI apply confirmation opened"
                    );
                    app.confirming = true;
                }
            }
            _ => {}
        }
    }
}

fn apply_selected(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    engine: &Engine,
    audit_ids: &[String],
    app: &mut App,
    console: &Console,
) -> Result<()> {
    suspend_terminal(terminal)?;

    let filter = FilterArgs {
        resources: app.selected.iter().cloned().collect(),
        ..FilterArgs::default()
    };
    let ids = engine.select(&filter)?;
    let outcomes = engine.apply_ids(&ids, |message| println!("{}", console.detail(message)));
    let failures: Vec<_> = outcomes
        .iter()
        .filter_map(|(id, result)| result.as_ref().err().map(|error| (id, error)))
        .collect();

    if failures.is_empty() {
        println!(
            "\n{}",
            console.success(format!(
                "Applied {} change(s) successfully.",
                outcomes.len()
            ))
        );
    } else {
        println!(
            "\n{}",
            console.error(format!("{} change(s) failed:", failures.len()))
        );
        for (id, error) in failures {
            println!("  {}: {error:#}", console.identity(id));
        }
    }
    print!("\nPress Enter to return to the dashboard...");
    io::stdout().flush()?;
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    resume_terminal(terminal)?;
    app.results = engine.audit_ids(audit_ids);
    app.selected.clear();
    app.message = format!("Applied {} change(s)", outcomes.len());
    app.clamp_cursor();
    Ok(())
}

fn render(frame: &mut Frame<'_>, app: &App) {
    let outer = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(8),
            Constraint::Length(3),
        ])
        .split(frame.area());
    render_header(frame, outer[0], app);

    let body = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(52), Constraint::Percentage(48)])
        .split(outer[1]);
    render_resources(frame, body[0], app);
    render_details(frame, body[1], app);
    render_footer(frame, outer[2], app);

    if app.confirming {
        render_confirmation(frame, app);
    }
}

fn render_header(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let healthy = app
        .results
        .iter()
        .filter(|result| result.status.is_healthy())
        .count();
    let issues = app.results.len().saturating_sub(healthy);
    let title = Line::from(vec![
        Span::styled(
            " dotfiles ",
            Style::default()
                .fg(theme::BACKGROUND_HIGHLIGHT)
                .bg(theme::BLUE)
                .add_modifier(Modifier::BOLD),
        ),
        Span::raw("  "),
        Span::styled(
            format!("{healthy} healthy"),
            Style::default().fg(theme::GREEN),
        ),
        Span::raw("  "),
        Span::styled(
            format!("{issues} issues"),
            Style::default().fg(if issues == 0 {
                theme::GREEN
            } else {
                theme::RED
            }),
        ),
        Span::raw("  "),
        Span::styled(
            format!("{} selected", app.selected.len()),
            Style::default().fg(theme::BLUE),
        ),
        Span::styled(
            if app.query.is_empty() {
                String::new()
            } else {
                format!("  filter: {}", app.query)
            },
            Style::default().fg(theme::VIOLET),
        ),
    ]);
    frame.render_widget(
        Paragraph::new(title).block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(theme::secondary()),
        ),
        area,
    );
}

fn render_resources(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let visible = app.visible();
    let items: Vec<_> = visible
        .iter()
        .filter_map(|index| app.results.get(*index))
        .map(|result| {
            let checkbox = if app.selected.contains(&result.id) {
                "[×]"
            } else if result.fixable && !result.status.is_healthy() {
                "[ ]"
            } else {
                "   "
            };
            ListItem::new(Line::from(vec![
                Span::styled(
                    format!("{} ", result.status.symbol()),
                    theme::status(result.status),
                ),
                Span::styled(
                    format!("{checkbox} "),
                    if app.selected.contains(&result.id) {
                        theme::identity()
                    } else {
                        theme::secondary()
                    },
                ),
                Span::styled(&result.id, Style::default().fg(theme::FOREGROUND)),
            ]))
        })
        .collect();
    let mut state = ListState::default();
    if !items.is_empty() {
        state.select(Some(app.cursor));
    }
    let title = if app.show_healthy {
        " Resources (all) "
    } else {
        " Resources (issues) "
    };
    let list = List::new(items)
        .block(
            Block::default()
                .title(Span::styled(title, theme::identity()))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(theme::BLUE)),
        )
        .highlight_style(theme::selected())
        .highlight_symbol("› ");
    frame.render_stateful_widget(list, area, &mut state);
}

fn render_details(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let lines = if let Some(result) = app.current() {
        vec![
            Line::styled(&result.id, theme::identity()),
            Line::raw(""),
            Line::raw(&result.description),
            Line::raw(""),
            Line::from(vec![
                Span::styled("Status: ", theme::secondary()),
                Span::styled(result.status.to_string(), theme::status(result.status)),
            ]),
            Line::from(vec![
                Span::styled("Reason: ", theme::secondary()),
                Span::raw(&result.summary),
            ]),
            Line::raw(""),
            Line::styled("Desired", theme::identity()),
            Line::raw(&result.desired),
            Line::raw(""),
            Line::styled("Actual", theme::identity()),
            Line::raw(&result.actual),
            Line::raw(""),
            Line::styled(
                if result.fixable {
                    "This resource can be applied automatically."
                } else if result.status.is_healthy() {
                    "No change needed."
                } else {
                    "Manual intervention is required."
                },
                if result.fixable || result.status.is_healthy() {
                    Style::default().fg(theme::GREEN)
                } else {
                    Style::default().fg(theme::RED)
                },
            ),
            Line::raw(""),
            Line::styled("Planned action", Style::default().fg(theme::YELLOW)),
            Line::styled(
                result.action.as_deref().unwrap_or("none"),
                if result.action.is_some() {
                    Style::default().fg(theme::YELLOW)
                } else {
                    theme::secondary()
                },
            ),
        ]
    } else {
        vec![Line::styled("No resources to display.", theme::secondary())]
    };
    frame.render_widget(
        Paragraph::new(lines)
            .block(
                Block::default()
                    .title(Span::styled(" Details ", theme::identity()))
                    .borders(Borders::ALL)
                    .border_style(theme::secondary()),
            )
            .wrap(Wrap { trim: false }),
        area,
    );
}

fn render_footer(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let help = Line::from(vec![
        key("j/k"),
        description(" move  "),
        key("/"),
        description(" search  "),
        key("space"),
        description(" select  "),
        key("enter"),
        description(" apply  "),
        key("r"),
        description(" audit  "),
        key("i"),
        description(" healthy  "),
        key("a/n"),
        description(" all/none  "),
        key("q"),
        description(" quit"),
    ]);
    frame.render_widget(
        Paragraph::new(vec![help, Line::styled(&app.message, theme::secondary())]).block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(theme::secondary()),
        ),
        area,
    );
}

fn key(value: &'static str) -> Span<'static> {
    Span::styled(value, theme::identity())
}

fn description(value: &'static str) -> Span<'static> {
    Span::styled(value, theme::secondary())
}

fn render_confirmation(frame: &mut Frame<'_>, app: &App) {
    let area = centered_rect(58, 7, frame.area());
    frame.render_widget(Clear, area);
    frame.render_widget(
        Paragraph::new(vec![
            Line::raw(format!("Apply {} selected change(s)?", app.selected.len())),
            Line::raw(""),
            Line::from(vec![
                Span::styled("Enter/y", theme::identity()),
                Span::raw(" confirm · "),
                Span::styled("n/Esc", Style::default().fg(theme::RED)),
                Span::raw(" cancel"),
            ]),
        ])
        .block(
            Block::default()
                .title(Span::styled(
                    " Confirm apply ",
                    Style::default()
                        .fg(theme::YELLOW)
                        .add_modifier(Modifier::BOLD),
                ))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(theme::YELLOW)),
        )
        .wrap(Wrap { trim: true }),
        area,
    );
}

fn centered_rect(width: u16, height: u16, area: Rect) -> Rect {
    let width = width.min(area.width);
    let height = height.min(area.height);
    Rect {
        x: area.x + area.width.saturating_sub(width) / 2,
        y: area.y + area.height.saturating_sub(height) / 2,
        width,
        height,
    }
}

fn start_terminal() -> Result<Terminal<CrosstermBackend<io::Stdout>>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout))?;
    terminal.clear()?;
    Ok(terminal)
}

fn stop_terminal(terminal: &mut Terminal<CrosstermBackend<io::Stdout>>) -> Result<()> {
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;
    Ok(())
}

fn suspend_terminal(terminal: &mut Terminal<CrosstermBackend<io::Stdout>>) -> Result<()> {
    stop_terminal(terminal)
}

fn resume_terminal(terminal: &mut Terminal<CrosstermBackend<io::Stdout>>) -> Result<()> {
    enable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        EnterAlternateScreen,
        EnableMouseCapture
    )?;
    terminal.clear()?;
    Ok(())
}
