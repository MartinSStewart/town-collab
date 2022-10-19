module Evergreen.V1.Bounds exposing (..)

import Evergreen.V1.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V1.Coord.Coord unit
        , max : Evergreen.V1.Coord.Coord unit
        }
