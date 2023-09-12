module Evergreen.V85.Ui exposing (..)

import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.Shaders
import Evergreen.V85.TextInput
import Pixels


type alias Padding =
    { topLeft : Evergreen.V85.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V85.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V85.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V85.Color.Color
        , fillColor : Evergreen.V85.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V85.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V85.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V85.Color.Color
        , color : Evergreen.V85.Color.Color
        , scale : Int
        , text : String
        , cachedSize : Evergreen.V85.Coord.Coord Pixels.Pixels
        }
    | TextInput
        { id : id
        , width : Int
        , isValid : Bool
        , state : Evergreen.V85.TextInput.State
        }
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V85.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V85.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V85.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
