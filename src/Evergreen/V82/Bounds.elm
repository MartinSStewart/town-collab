module Evergreen.V82.Bounds exposing (..)

import Evergreen.V82.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V82.Coord.Coord unit
        , max : Evergreen.V82.Coord.Coord unit
        }
