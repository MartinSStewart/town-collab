module Evergreen.V134.Ui exposing (..)

import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.Sprite
import Evergreen.V134.TextInput
import Evergreen.V134.TextInputMultiline
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V134.TextInput.State
    , textScale : Int
    }


type alias TextInputMultilineData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V134.TextInputMultiline.State
    , textScale : Int
    , dummyField : ()
    }


type alias Padding =
    { topLeft : Evergreen.V134.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V134.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V134.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V134.Color.Color
        , fillColor : Evergreen.V134.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , borderAndFillHover : BorderAndFill
    , cachedSize : Evergreen.V134.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V134.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V134.Color.Color
        , color : Evergreen.V134.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V134.Coord.Coord Pixels.Pixels
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
        , cachedSize : Evergreen.V134.Coord.Coord Pixels.Pixels
        , id : Maybe id
        }
        (Element id)
    | Quads
        { size : Evergreen.V134.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V134.Sprite.Vertex
        }
    | Empty
