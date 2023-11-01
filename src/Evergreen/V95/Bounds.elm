module Evergreen.V95.Bounds exposing (..)

import Evergreen.V95.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V95.Coord.Coord unit
        , max : Evergreen.V95.Coord.Coord unit
        }
