module Evergreen.V57.Bounds exposing (..)

import Evergreen.V57.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V57.Coord.Coord unit
        , max : Evergreen.V57.Coord.Coord unit
        }
