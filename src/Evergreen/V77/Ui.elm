module Evergreen.V77.Ui exposing (..)

import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.Shaders
import Evergreen.V77.TextInput
import Pixels


type alias Padding =
    { topLeft : Evergreen.V77.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V77.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V77.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V77.Color.Color
        , fillColor : Evergreen.V77.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V77.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V77.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V77.Color.Color
        , color : Evergreen.V77.Color.Color
        , scale : Int
        , text : String
        , cachedSize : Evergreen.V77.Coord.Coord Pixels.Pixels
        }
    | TextInput
        { id : id
        , width : Int
        , isValid : Bool
        , state : Evergreen.V77.TextInput.State
        }
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V77.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V77.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V77.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
