use std::{collections::VecDeque, io, sync::Mutex};

use crate::system::{CommandOutput, CommandRequest, CommandRunner};

#[derive(Default)]
pub(super) struct StubRunner {
    captured: Mutex<VecDeque<CommandOutput>>,
    run_results: Mutex<VecDeque<bool>>,
    requests: Mutex<Vec<CommandRequest>>,
}

impl StubRunner {
    pub fn with_captured(outputs: impl IntoIterator<Item = CommandOutput>) -> Self {
        Self {
            captured: Mutex::new(outputs.into_iter().collect()),
            ..Self::default()
        }
    }

    pub fn with_run_results(results: impl IntoIterator<Item = bool>) -> Self {
        Self {
            run_results: Mutex::new(results.into_iter().collect()),
            ..Self::default()
        }
    }

    pub fn requests(&self) -> Vec<CommandRequest> {
        self.requests.lock().unwrap().clone()
    }
}

impl CommandRunner for StubRunner {
    fn capture(&self, request: &CommandRequest) -> io::Result<CommandOutput> {
        self.requests.lock().unwrap().push(request.clone());
        self.captured
            .lock()
            .unwrap()
            .pop_front()
            .ok_or_else(|| io::Error::other("no capture response configured"))
    }

    fn run(&self, request: &CommandRequest) -> io::Result<bool> {
        self.requests.lock().unwrap().push(request.clone());
        self.run_results
            .lock()
            .unwrap()
            .pop_front()
            .ok_or_else(|| io::Error::other("no run response configured"))
    }
}
