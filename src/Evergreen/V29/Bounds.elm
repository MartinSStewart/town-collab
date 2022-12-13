module Evergreen.V29.Bounds exposing (..)

import Evergreen.V29.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V29.Coord.Coord unit
        , max : Evergreen.V29.Coord.Coord unit
        }
