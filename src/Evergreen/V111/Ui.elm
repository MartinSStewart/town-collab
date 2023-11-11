module Evergreen.V111.Ui exposing (..)

import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.Sprite
import Evergreen.V111.TextInput
import Pixels


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : Evergreen.V111.TextInput.State
    , textScale : Int
    }


type alias Padding =
    { topLeft : Evergreen.V111.Coord.Coord Pixels.Pixels
    , bottomRight : Evergreen.V111.Coord.Coord Pixels.Pixels
    }


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Evergreen.V111.Color.Color
    | BorderAndFill
        { borderWidth : Int
        , borderColor : Evergreen.V111.Color.Color
        , fillColor : Evergreen.V111.Color.Color
        }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Evergreen.V111.Coord.Coord Pixels.Pixels
    , inFront : List (Element id)
    }


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Evergreen.V111.Coord.Coord Pixels.Pixels
    }


type Element id
    = Text
        { outline : Maybe Evergreen.V111.Color.Color
        , color : Evergreen.V111.Color.Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Evergreen.V111.Coord.Coord Pixels.Pixels
        }
    | TextInput (TextInputData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Evergreen.V111.Coord.Coord Pixels.Pixels
        }
        (Element id)
    | Quads
        { size : Evergreen.V111.Coord.Coord Pixels.Pixels
        , vertices : List Evergreen.V111.Sprite.Vertex
        }
    | Empty
    | IgnoreInputs (Element id)
