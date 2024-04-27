module Evergreen.V126.Ui exposing (..)

import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.Sprite
import Evergreen.V126.TextInput
import Evergreen.V126.TextInputMultiline
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V126.TextInput.State
    , textScale : Int
    }


type alias TextInputMultilineData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V126.TextInputMultiline.State
    , textScale : Int
    , dummyField : ()
    }


type alias Padding =
    { topLeft : Evergreen.V126.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V126.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V126.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V126.Color.Color
        , fillColor : Evergreen.V126.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , borderAndFillHover : BorderAndFill
    , cachedSize : Evergreen.V126.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V126.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V126.Color.Color
        , color : Evergreen.V126.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V126.Coord.Coord Pixels.Pixels
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
        , cachedSize : Evergreen.V126.Coord.Coord Pixels.Pixels
        , id : Maybe id
        }
        (Element id)
    | Quads
        { size : Evergreen.V126.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V126.Sprite.Vertex
        }
    | Empty
