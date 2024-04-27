module Evergreen.V126.Bounds exposing (..)

import Evergreen.V126.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V126.Coord.Coord unit
        , max : Evergreen.V126.Coord.Coord unit
        }
