module Evergreen.V109.Ui exposing (..)

import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.Sprite
import Evergreen.V109.TextInput
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V109.TextInput.State
    , textScale : Int
    }


type alias Padding =
    { topLeft : Evergreen.V109.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V109.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V109.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V109.Color.Color
        , fillColor : Evergreen.V109.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V109.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V109.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V109.Color.Color
        , color : Evergreen.V109.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V109.Coord.Coord Pixels.Pixels
        }
    | TextInput (TextInputData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V109.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V109.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V109.Sprite.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
