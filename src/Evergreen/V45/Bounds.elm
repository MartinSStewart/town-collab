module Evergreen.V45.Bounds exposing (..)

import Evergreen.V45.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V45.Coord.Coord unit
        , max : Evergreen.V45.Coord.Coord unit
        }
