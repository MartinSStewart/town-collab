module Evergreen.V75.Ui exposing (..)

import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.Shaders
import Evergreen.V75.TextInput
import Pixels


type alias Padding =
    { topLeft : Evergreen.V75.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V75.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V75.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V75.Color.Color
        , fillColor : Evergreen.V75.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V75.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V75.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V75.Color.Color
        , color : Evergreen.V75.Color.Color
        , scale : Int
        , text : String
        , cachedSize : Evergreen.V75.Coord.Coord Pixels.Pixels
        }
    | TextInput
        { id : id
        , width : Int
        , isValid : Bool
        , state : Evergreen.V75.TextInput.State
        }
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V75.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V75.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V75.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
