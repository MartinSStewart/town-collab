module Evergreen.V89.Ui exposing (..)

import Evergreen.V89.Color
import Evergreen.V89.Coord
import Evergreen.V89.Shaders
import Evergreen.V89.TextInput
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V89.TextInput.State
    }


type alias Padding =
    { topLeft : Evergreen.V89.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V89.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V89.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V89.Color.Color
        , fillColor : Evergreen.V89.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V89.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V89.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V89.Color.Color
        , color : Evergreen.V89.Color.Color
        , scale : Int
        , text : String
        , cachedSize : Evergreen.V89.Coord.Coord Pixels.Pixels
        }
    | TextInput (TextInputData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V89.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V89.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V89.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
