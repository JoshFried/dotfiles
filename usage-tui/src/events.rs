//! Deliver terminal input, clipboard results and wake notifications to the UI.
//! Workers use a nonblocking wake signal so a full event queue cannot stall a
//! collector.

use std::sync::{Arc, Mutex, mpsc::SyncSender};

pub enum AppEvent {
    Terminal(crossterm::event::Event),
    Wake,
    InputError(String),
    Clipboard {
        text: String,
        native: Result<bool, String>,
    },
}

#[derive(Clone, Default)]
pub struct Wake(Arc<Mutex<Option<SyncSender<AppEvent>>>>);

impl Wake {
    pub fn attach(&self, sender: SyncSender<AppEvent>) {
        *self.0.lock().unwrap_or_else(|e| e.into_inner()) = Some(sender);
    }

    pub fn notify(&self) {
        if let Some(sender) = &*self.0.lock().unwrap_or_else(|e| e.into_inner()) {
            let _ = sender.try_send(AppEvent::Wake);
        }
    }
}
