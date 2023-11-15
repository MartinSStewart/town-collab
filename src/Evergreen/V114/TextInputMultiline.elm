module Evergreen.V114.TextInputMultiline exposing (..)


type alias State =
    { cursorPosition : Int
    , cursorSize : Int
    , text : String
    }


type alias Model =
    { current : State
    , undoHistory : List State
    , redoHistory : List State
    , dummyField : ()
    }
