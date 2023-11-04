module Evergreen.V106.Bounds exposing (..)

import Evergreen.V106.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V106.Coord.Coord unit
        , max : Evergreen.V106.Coord.Coord unit
        }
