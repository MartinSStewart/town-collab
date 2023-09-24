module Evergreen.V88.Ui exposing (..)

import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.Shaders
import Evergreen.V88.TextInput
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V88.TextInput.State
    }


type alias Padding =
    { topLeft : Evergreen.V88.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V88.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V88.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V88.Color.Color
        , fillColor : Evergreen.V88.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V88.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V88.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V88.Color.Color
        , color : Evergreen.V88.Color.Color
        , scale : Int
        , text : String
        , cachedSize : Evergreen.V88.Coord.Coord Pixels.Pixels
        }
    | TextInput (TextInputData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V88.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V88.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V88.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
