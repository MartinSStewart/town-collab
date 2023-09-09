module Evergreen.V81.Ui exposing (..)

import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.Shaders
import Evergreen.V81.TextInput
import Pixels


type alias Padding =
    { topLeft : Evergreen.V81.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V81.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V81.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V81.Color.Color
        , fillColor : Evergreen.V81.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V81.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V81.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V81.Color.Color
        , color : Evergreen.V81.Color.Color
        , scale : Int
        , text : String
        , cachedSize : Evergreen.V81.Coord.Coord Pixels.Pixels
        }
    | TextInput
        { id : id
        , width : Int
        , isValid : Bool
        , state : Evergreen.V81.TextInput.State
        }
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V81.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V81.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V81.Shaders.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
