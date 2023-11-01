module Evergreen.V97.Bounds exposing (..)

import Evergreen.V97.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V97.Coord.Coord unit
        , max : Evergreen.V97.Coord.Coord unit
        }
