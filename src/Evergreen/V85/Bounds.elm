module Evergreen.V85.Bounds exposing (..)

import Evergreen.V85.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V85.Coord.Coord unit
        , max : Evergreen.V85.Coord.Coord unit
        }
