module Evergreen.V125.TextInputMultiline exposing (..)


type alias State =
    { cursorIndex : Int
    , cursorSize : Int
    , text : String
    }


type alias Model =
    { current : State
    , undoHistory : List State
    , redoHistory : List State
    , dummyField : ()
    }
