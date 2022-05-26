use serde::{Deserialize, Serialize};
use std::sync::Arc;

// Msgs sent between the Remote Control (client) and Totem (server).

#[derive(Clone, Debug, Eq, PartialEq, Hash, Serialize, Deserialize)]
pub struct AppKey(pub Arc<str>);

impl From<&str> for AppKey {
    fn from(s: &str) -> Self {
        AppKey(Arc::from(s))
    }
}

impl From<String> for AppKey {
    fn from(s: String) -> Self {
        AppKey(Arc::from(s))
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub enum ToClientMsg {
    // current app, apps
    Start(AppKey, Vec<AppKey>),
    AppChanged(AppKey),
    Heartbeat,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum FromClientMsg {
    // device name
    Start(Arc<str>),
    Finish,
    LaunchApp(AppKey),
    SendToAppMsg(AppKey, ToAppMsg),
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum ToAppMsg {
    ToDancer(ToDancerMsg),
    ToDoom(ToDoomMsg),
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum ToDoomMsg {
    Up(bool),
    Down(bool),
    Left(bool),
    Right(bool),
    TurnLeft(bool),
    TurnRight(bool),
    Fire(bool),
    Use,
    Esc,
    Enter,
    Key(i8),
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum ToDancerMsg {
    // Is u32 to not be platform specific. Will be casted to a usize later.
    SetAnimationIdx(u32),
    SetBpm(f32),
    Reset,
    // (size, duration in ms, text)
    ShowText(TextSize, u32, Arc<str>),
    ClearText,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub enum TextSize {
    Normal,
    Large,
}

