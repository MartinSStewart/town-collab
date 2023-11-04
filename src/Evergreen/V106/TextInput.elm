module Evergreen.V106.TextInput exposing (..)


type alias State =
    { cursorPosition : Int
    , cursorSize : Int
    , text : String
    }


type alias Model =
    { current : State
    , undoHistory : List State
    , redoHistory : List State
    }
