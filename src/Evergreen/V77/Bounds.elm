module Evergreen.V77.Bounds exposing (..)

import Evergreen.V77.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V77.Coord.Coord unit
        , max : Evergreen.V77.Coord.Coord unit
        }
