use std::sync::Arc;
use totem_common::{AppKey, ToAppMsg};

// Msgs sent between the Swift and Rust layers.

// To Rust.
#[derive(Clone, Debug)]
pub enum ToUiMsg {
    LaunchApp(AppKey),
    SendToAppMsg(AppKey, ToAppMsg),
}

// From Rust.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum FromUiMsg {
    UpdateState(UiState),
    // reason
    Finish(Result<(), Arc<str>>),
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UiState {
    pub apps: Option<(AppKey, Vec<AppKey>)>,
    pub pending_app: Option<AppKey>,
    pub network_state: NetworkState,
}

impl UiState {
    pub fn new(
        apps: Option<(AppKey, Vec<AppKey>)>,
        pending_app: Option<AppKey>,
        network_state: NetworkState,
    ) -> Self {
        Self {
            apps,
            pending_app,
            network_state,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum NetworkState {
    Connected,
    Connecting(Result<(), Arc<str>>),
}

