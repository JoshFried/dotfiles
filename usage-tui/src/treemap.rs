use ratatui::layout::Rect;
use std::collections::HashSet;

#[derive(Clone, Debug, PartialEq)]
pub struct Item {
    pub id: String,
    pub name: String,
    pub size: u64,
    pub detail: String,
}

#[derive(Clone, Debug)]
pub struct Tile {
    pub rect: Rect,
    pub members: Vec<usize>,
}

#[derive(Clone, Copy)]
pub enum Direction {
    Left,
    Down,
    Up,
    Right,
}

#[derive(Clone, Copy, Default, Debug, PartialEq, Eq)]
pub enum Sizing {
    Balanced,
    #[default]
    Proportional,
}

impl Sizing {
    pub fn label(self) -> &'static str {
        match self {
            Self::Balanced => "balanced",
            Self::Proportional => "proportional",
        }
    }

    pub fn description(self) -> &'static str {
        match self {
            Self::Balanced => "Balanced · smaller tiles enlarged",
            Self::Proportional => "Proportional · area reflects bytes",
        }
    }
}

pub fn list_only(area: Rect) -> bool {
    area.width < 35 || area.height < 8
}

fn worst(row: &[f64], side: f64) -> f64 {
    let sum: f64 = row.iter().sum();
    let min = row.iter().copied().fold(f64::INFINITY, f64::min);
    let max = row.iter().copied().fold(0.0, f64::max);
    if sum == 0.0 || min == 0.0 || side == 0.0 {
        return f64::INFINITY;
    }
    (side * side * max / (sum * sum)).max(sum * sum / (side * side * min))
}

fn layout(weights: &[f64], area: Rect) -> Vec<Rect> {
    let total: f64 = weights.iter().sum();
    if total == 0.0 || area.is_empty() {
        return Vec::new();
    }
    let physical_area = f64::from(area.width) * f64::from(area.height) * 2.0;
    let scaled: Vec<f64> = weights.iter().map(|w| *w / total * physical_area).collect();
    let mut result = Vec::with_capacity(weights.len());
    let mut remaining = area;
    let mut start = 0;
    while start < scaled.len() && !remaining.is_empty() {
        let horizontal = f64::from(remaining.width) >= f64::from(remaining.height) * 2.0;
        let short = if horizontal {
            f64::from(remaining.height) * 2.0
        } else {
            f64::from(remaining.width)
        };
        let mut end = start + 1;
        while end < scaled.len()
            && worst(&scaled[start..=end], short) <= worst(&scaled[start..end], short)
        {
            end += 1;
        }
        let row = &scaled[start..end];
        let row_sum: f64 = row.iter().sum();
        let remaining_sum: f64 = scaled[start..].iter().sum();
        let extent = if horizontal {
            remaining.width
        } else {
            remaining.height
        };
        let thickness = if end == scaled.len() {
            extent
        } else {
            ((f64::from(extent) * row_sum / remaining_sum).round() as u16).clamp(1, extent)
        };
        let length = if horizontal {
            remaining.height
        } else {
            remaining.width
        };
        let mut boundary = 0;
        let mut cumulative = 0.0;
        for (i, weight) in row.iter().enumerate() {
            cumulative += weight;
            let next = if i + 1 == row.len() {
                length
            } else {
                (f64::from(length) * cumulative / row_sum).round() as u16
            };
            let rect = if horizontal {
                Rect::new(
                    remaining.x,
                    remaining.y + boundary,
                    thickness,
                    next - boundary,
                )
            } else {
                Rect::new(
                    remaining.x + boundary,
                    remaining.y,
                    next - boundary,
                    thickness,
                )
            };
            result.push(rect);
            boundary = next;
        }
        if horizontal {
            remaining.x += thickness;
            remaining.width -= thickness;
        } else {
            remaining.y += thickness;
            remaining.height -= thickness;
        }
        start = end;
    }
    result.resize(weights.len(), Rect::default());
    result
}

pub fn tiles(items: &[Item], area: Rect) -> Vec<Tile> {
    tiles_with_sizing(items, area, Sizing::Proportional)
}

pub fn tiles_with_sizing(items: &[Item], area: Rect, sizing: Sizing) -> Vec<Tile> {
    tiles_with_thresholds(items, area, sizing, None)
}

fn weights(items: &[Item], sizing: Sizing) -> Vec<f64> {
    let count = items.iter().filter(|item| item.size > 0).count();
    let total: f64 = items.iter().map(|item| item.size as f64).sum();
    let softened_total: f64 = items.iter().map(|item| (item.size as f64).sqrt()).sum();
    items
        .iter()
        .map(|item| {
            if item.size == 0 {
                return 0.0;
            }
            match sizing {
                Sizing::Proportional => item.size as f64 / total,
                // Reserve room for labels even when byte counts differ by many orders of magnitude.
                Sizing::Balanced => {
                    0.65 / count as f64 + 0.35 * (item.size as f64).sqrt() / softened_total
                }
            }
        })
        .collect()
}

fn tiles_with_thresholds(
    items: &[Item],
    area: Rect,
    sizing: Sizing,
    previous: Option<&HashSet<String>>,
) -> Vec<Tile> {
    if !items.iter().any(|item| item.size > 0) || area.is_empty() {
        return Vec::new();
    }
    let weights = weights(items, sizing);
    let cells = f64::from(area.width) * f64::from(area.height);
    let mut groups: Vec<Vec<usize>> = Vec::new();
    let mut small = Vec::new();
    for (i, item) in items.iter().enumerate() {
        if item.size == 0 {
            continue;
        }
        let threshold = match sizing {
            Sizing::Balanced => {
                previous.map_or(40.0, |ids| if ids.contains(&item.id) { 28.0 } else { 60.0 })
            }
            Sizing::Proportional => {
                previous.map_or(12.0, |ids| if ids.contains(&item.id) { 8.0 } else { 20.0 })
            }
        };
        if weights[i] * cells < threshold {
            small.push(i);
        } else {
            groups.push(vec![i]);
        }
    }
    if !small.is_empty() {
        groups.push(small);
    }
    loop {
        let group_count = groups.len();
        let grouped_weights: Vec<f64> = groups
            .iter()
            .map(|group| group.iter().map(|i| weights[*i]).sum())
            .collect();
        let rectangles = layout(&grouped_weights, area);
        let (min_width, min_height) = match sizing {
            Sizing::Balanced => (10, 4),
            Sizing::Proportional => (4, 3),
        };
        let tiny: Vec<usize> = rectangles
            .iter()
            .enumerate()
            .filter(|(_, rect)| rect.width < min_width || rect.height < min_height)
            .map(|(i, _)| i)
            .collect();
        if tiny.is_empty() || groups.len() <= 1 {
            return groups
                .into_iter()
                .zip(rectangles)
                .map(|(members, rect)| Tile { rect, members })
                .collect();
        }
        let mut merged = Vec::new();
        let mut kept = Vec::new();
        for (i, group) in groups.into_iter().enumerate() {
            if tiny.contains(&i) || group.len() > 1 {
                merged.extend(group);
            } else {
                kept.push(group);
            }
        }
        if kept.len() + 1 >= group_count && !kept.is_empty() {
            merged.extend(kept.pop().unwrap());
        }
        kept.push(merged);
        groups = kept;
    }
}

#[derive(Default)]
pub struct StableLayout {
    area: Rect,
    sizing: Sizing,
    keys: Vec<String>,
    rectangles: Vec<Rect>,
    shares: Vec<f64>,
    individuals: HashSet<String>,
}

impl StableLayout {
    pub fn clear(&mut self) {
        *self = Self::default();
    }

    pub fn tiles(&mut self, items: &[Item], area: Rect) -> Vec<Tile> {
        self.tiles_with_sizing(items, area, Sizing::Proportional)
    }

    pub fn tiles_with_sizing(&mut self, items: &[Item], area: Rect, sizing: Sizing) -> Vec<Tile> {
        let previous = (!self.keys.is_empty() && self.area == area && self.sizing == sizing)
            .then_some(&self.individuals);
        let mut tiles = tiles_with_thresholds(items, area, sizing, previous);
        let keys: Vec<_> = tiles
            .iter()
            .map(|tile| {
                if tile.members.len() > 1 {
                    "\0other".into()
                } else {
                    items[tile.members[0]].id.clone()
                }
            })
            .collect();
        let weights = weights(items, sizing);
        let shares: Vec<f64> = tiles
            .iter()
            .map(|tile| tile.members.iter().map(|i| weights[*i]).sum::<f64>())
            .collect();
        let changes: Vec<f64> = shares
            .iter()
            .zip(&self.shares)
            .map(|(a, b)| (a - b).abs())
            .collect();
        let steady = self.area == area
            && self.sizing == sizing
            && self.keys == keys
            && changes.iter().all(|change| *change <= 0.04)
            && changes.iter().sum::<f64>() <= 0.08;
        if steady {
            for (tile, rect) in tiles.iter_mut().zip(&self.rectangles) {
                tile.rect = *rect;
            }
        } else {
            self.area = area;
            self.sizing = sizing;
            self.keys = keys;
            self.rectangles = tiles.iter().map(|tile| tile.rect).collect();
            self.shares = shares;
        }
        self.individuals = tiles
            .iter()
            .filter(|tile| tile.members.len() == 1)
            .map(|tile| items[tile.members[0]].id.clone())
            .collect();
        tiles
    }
}

pub fn neighbor(tiles: &[Tile], selected: usize, direction: Direction) -> Option<usize> {
    let from = tiles.get(selected)?.rect;
    let center = |r: Rect| {
        (
            f64::from(r.x) + f64::from(r.width) / 2.0,
            f64::from(r.y) + f64::from(r.height) / 2.0,
        )
    };
    let (x, y) = center(from);
    tiles
        .iter()
        .enumerate()
        .filter(|(i, _)| *i != selected)
        .filter_map(|(i, tile)| {
            let (nx, ny) = center(tile.rect);
            let (forward, sideways) = match direction {
                Direction::Left => (x - nx, (ny - y).abs() * 2.0),
                Direction::Right => (nx - x, (ny - y).abs() * 2.0),
                Direction::Up => ((y - ny) * 2.0, (nx - x).abs()),
                Direction::Down => ((ny - y) * 2.0, (nx - x).abs()),
            };
            (forward > 0.0).then_some((i, forward + sideways * 3.0))
        })
        .min_by(|a, b| a.1.total_cmp(&b.1))
        .map(|(i, _)| i)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn item(size: u64) -> Item {
        Item {
            id: size.to_string(),
            name: size.to_string(),
            size,
            detail: String::new(),
        }
    }

    #[test]
    fn partition_covers_canvas_without_overlap() {
        for sizing in [Sizing::Balanced, Sizing::Proportional] {
            for width in 1..70 {
                for height in 1..25 {
                    let area = Rect::new(2, 3, width, height);
                    let mapped =
                        tiles_with_sizing(&[item(900), item(80), item(20), item(1)], area, sizing);
                    let mut cells = std::collections::HashSet::new();
                    for tile in mapped {
                        for y in tile.rect.y..tile.rect.bottom() {
                            for x in tile.rect.x..tile.rect.right() {
                                assert!(area.contains((x, y).into()));
                                assert!(cells.insert((x, y)));
                            }
                        }
                    }
                    assert_eq!(cells.len(), usize::from(width) * usize::from(height));
                }
            }
        }
    }

    #[test]
    fn balanced_sizing_keeps_extreme_size_differences_readable() {
        let area = Rect::new(0, 0, 80, 20);
        let items = [item(u64::MAX), item(2), item(1), item(0)];
        let mapped = tiles_with_sizing(&items, area, Sizing::Balanced);
        assert_eq!(mapped.len(), 3);
        assert!(mapped.iter().all(|tile| {
            tile.members.len() == 1 && tile.rect.width >= 10 && tile.rect.height >= 4
        }));
        let largest = mapped.iter().find(|tile| tile.members == [0]).unwrap();
        assert!(f64::from(largest.rect.area()) / f64::from(area.area()) < 0.60);
        assert_eq!(items[0].size, u64::MAX);
        assert!(!mapped.iter().any(|tile| tile.members.contains(&3)));
    }

    #[test]
    fn balanced_sizing_aggregates_only_when_entries_cannot_fit() {
        let area = Rect::new(0, 0, 120, 30);
        let items: Vec<_> = std::iter::once(item(1_000_000_000_000))
            .chain((1..=15).map(item))
            .collect();
        let mapped = tiles_with_sizing(&items, area, Sizing::Balanced);
        assert_eq!(mapped.len(), items.len());
        assert!(mapped.iter().all(|tile| {
            tile.members.len() == 1 && tile.rect.width >= 10 && tile.rect.height >= 4
        }));
        let crowded = tiles_with_sizing(&items, Rect::new(0, 0, 40, 8), Sizing::Balanced);
        assert!(crowded.iter().any(|tile| tile.members.len() > 1));
        let mut members: Vec<_> = crowded
            .iter()
            .flat_map(|tile| tile.members.iter().copied())
            .collect();
        members.sort_unstable();
        assert_eq!(members, (0..items.len()).collect::<Vec<_>>());
    }

    #[test]
    fn stable_layout_switches_sizing_without_reusing_old_rectangles() {
        let items = [item(900), item(80), item(20)];
        let area = Rect::new(0, 0, 80, 24);
        let mut stable = StableLayout::default();
        let balanced: Vec<_> = stable
            .tiles_with_sizing(&items, area, Sizing::Balanced)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        let proportional: Vec<_> = stable
            .tiles_with_sizing(&items, area, Sizing::Proportional)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        assert_ne!(balanced, proportional);
        let restored: Vec<_> = stable
            .tiles_with_sizing(&items, area, Sizing::Balanced)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        assert_eq!(balanced, restored);
    }

    #[test]
    fn small_items_aggregate_and_zero_is_list_only() {
        let mapped = tiles(
            &[item(10_000), item(1), item(2), item(0)],
            Rect::new(0, 0, 80, 20),
        );
        assert!(
            mapped
                .iter()
                .any(|tile| tile.members.contains(&1) && tile.members.contains(&2))
        );
        assert!(!mapped.iter().any(|tile| tile.members.contains(&3)));
        assert!(list_only(Rect::new(0, 0, 20, 10)));
        assert!(!list_only(Rect::new(0, 0, 80, 20)));
    }

    #[test]
    fn navigation_uses_geometry() {
        let tiles = vec![
            Tile {
                rect: Rect::new(0, 0, 10, 5),
                members: vec![0],
            },
            Tile {
                rect: Rect::new(10, 0, 10, 5),
                members: vec![1],
            },
            Tile {
                rect: Rect::new(0, 5, 10, 5),
                members: vec![2],
            },
        ];
        assert_eq!(neighbor(&tiles, 0, Direction::Right), Some(1));
        assert_eq!(neighbor(&tiles, 0, Direction::Down), Some(2));
        assert_eq!(neighbor(&tiles, 0, Direction::Left), None);
    }

    #[test]
    fn physical_aspect_and_rounding_track_area() {
        let rectangles = layout(&[1.0, 1.0, 1.0, 1.0], Rect::new(0, 0, 40, 20));
        assert_eq!(rectangles.len(), 4);
        for rect in rectangles {
            assert_eq!(u32::from(rect.width) * u32::from(rect.height), 200);
            assert_eq!(rect.width, rect.height * 2);
        }
    }

    #[test]
    fn many_equal_or_skewed_entries_still_partition_and_aggregate() {
        let area = Rect::new(3, 7, 60, 18);
        for weights in [
            vec![1; 2_000],
            (1..=500).collect(),
            vec![0, 1, 10, 100, 10_000_000],
        ] {
            let entries: Vec<_> = weights.into_iter().map(item).collect();
            let mapped = tiles(&entries, area);
            let mut cells = std::collections::HashSet::new();
            let mut members = std::collections::HashSet::new();
            for tile in mapped {
                for member in tile.members {
                    assert!(members.insert(member));
                }
                for y in tile.rect.y..tile.rect.bottom() {
                    for x in tile.rect.x..tile.rect.right() {
                        assert!(area.contains((x, y).into()));
                        assert!(cells.insert((x, y)));
                    }
                }
            }
            assert_eq!(cells.len(), 1080);
            assert_eq!(members.len(), entries.iter().filter(|i| i.size > 0).count());
        }
    }

    #[test]
    fn stable_layout_holds_small_changes_and_refreshes_meaningful_changes() {
        let area = Rect::new(0, 0, 80, 24);
        let mut items = vec![item(60), item(40)];
        let mut stable = StableLayout::default();
        let first: Vec<_> = stable
            .tiles(&items, area)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        items[0].size = 61;
        items[1].size = 39;
        let small: Vec<_> = stable
            .tiles(&items, area)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        assert_eq!(small, first);
        stable.clear();
        let refreshed: Vec<_> = stable
            .tiles(&items, area)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        assert_ne!(refreshed, first);
        items[0].size = 80;
        items[1].size = 20;
        let large: Vec<_> = stable
            .tiles(&items, area)
            .iter()
            .map(|tile| tile.rect)
            .collect();
        assert_ne!(large, refreshed);
        let resized = stable.tiles(&items, Rect::new(0, 0, 120, 30));
        assert_eq!(
            resized
                .iter()
                .map(|tile| u32::from(tile.rect.width) * u32::from(tile.rect.height))
                .sum::<u32>(),
            3600
        );
    }

    #[test]
    fn stable_layout_remaps_indices_when_processes_exit_or_arrive() {
        let area = Rect::new(0, 0, 80, 24);
        let mut items = vec![item(60), item(40), item(30)];
        let mut stable = StableLayout::default();
        stable.tiles(&items, area);
        items.remove(0);
        items.push(item(50));
        let mapped = stable.tiles(&items, area);
        let mut members: Vec<_> = mapped
            .iter()
            .flat_map(|tile| tile.members.iter().copied())
            .collect();
        members.sort_unstable();
        assert_eq!(members, vec![0, 1, 2]);
    }
}
