module Evergreen.V91.Ui exposing (..)

import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.Shaders
import Evergreen.V91.TextInput
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V91.TextInput.State
    }


type alias Padding =
    { topLeft : Evergreen.V91.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V91.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V91.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V91.Color.Color
        , fillColor : Evergreen.V91.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V91.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V91.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V91.Color.Color
        , color : Evergreen.V91.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V91.Coord.Coord Pixels.Pixels
        }
    | TextInput (TextInputData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V91.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V91.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V91.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
