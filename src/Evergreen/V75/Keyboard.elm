module Evergreen.V75.Keyboard exposing (..)


type RawKey
    = RawKey String


type Msg
    = Down RawKey
    | Up RawKey


type Key
    = Character String
    | Alt
    | AltGraph
    | CapsLock
    | Control
    | Fn
    | FnLock
    | Hyper
    | Meta
    | NumLock
    | ScrollLock
    | Shift
    | Super
    | Symbol
    | SymbolLock
    | Enter
    | Tab
    | Spacebar
    | ArrowDown
    | ArrowLeft
    | ArrowRight
    | ArrowUp
    | End
    | Home
    | PageDown
    | PageUp
    | Backspace
    | Clear
    | Copy
    | CrSel
    | Cut
    | Delete
    | EraseEof
    | ExSel
    | Insert
    | Paste
    | Redo
    | Undo
    | F1
    | F2
    | F3
    | F4
    | F5
    | F6
    | F7
    | F8
    | F9
    | F10
    | F11
    | F12
    | F13
    | F14
    | F15
    | F16
    | F17
    | F18
    | F19
    | F20
    | Again
    | Attn
    | Cancel
    | ContextMenu
    | Escape
    | Execute
    | Find
    | Finish
    | Help
    | Pause
    | Play
    | Props
    | Select
    | ZoomIn
    | ZoomOut
    | AppSwitch
    | Call
    | Camera
    | CameraFocus
    | EndCall
    | GoBack
    | GoHome
    | HeadsetHook
    | LastNumberRedial
    | Notification
    | MannerMode
    | VoiceDial
    | ChannelDown
    | ChannelUp
    | MediaFastForward
    | MediaPause
    | MediaPlay
    | MediaPlayPause
    | MediaRecord
    | MediaRewind
    | MediaStop
    | MediaTrackNext
    | MediaTrackPrevious
