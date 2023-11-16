module Evergreen.V115.Ui exposing (..)

import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.Sprite
import Evergreen.V115.TextInput
import Evergreen.V115.TextInputMultiline
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V115.TextInput.State
    , textScale : Int
    }


type alias TextInputMultilineData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V115.TextInputMultiline.State
    , textScale : Int
    , dummyField : ()
    }


type alias Padding =
    { topLeft : Evergreen.V115.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V115.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V115.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V115.Color.Color
        , fillColor : Evergreen.V115.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V115.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V115.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V115.Color.Color
        , color : Evergreen.V115.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V115.Coord.Coord Pixels.Pixels
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
        , cachedSize : Evergreen.V115.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V115.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V115.Sprite.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
