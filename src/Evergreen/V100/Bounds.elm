module Evergreen.V100.Bounds exposing (..)

import Evergreen.V100.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V100.Coord.Coord unit
        , max : Evergreen.V100.Coord.Coord unit
        }
