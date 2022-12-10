module Evergreen.V28.Bounds exposing (..)

import Evergreen.V28.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V28.Coord.Coord unit
        , max : Evergreen.V28.Coord.Coord unit
        }
