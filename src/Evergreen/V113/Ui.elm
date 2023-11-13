module Evergreen.V113.Ui exposing (..)

import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.Sprite
import Evergreen.V113.TextInput
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V113.TextInput.State
    , textScale : Int
    }


type alias TextInputMultilineData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V113.TextInput.State
    , textScale : Int
    , dummyField : ()
    }


type alias Padding =
    { topLeft : Evergreen.V113.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V113.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V113.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V113.Color.Color
        , fillColor : Evergreen.V113.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V113.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V113.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V113.Color.Color
        , color : Evergreen.V113.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V113.Coord.Coord Pixels.Pixels
        }
    | TextInput (TextInputData id)
    | TextInputMultiline (TextInputMultilineData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V113.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V113.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V113.Sprite.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
