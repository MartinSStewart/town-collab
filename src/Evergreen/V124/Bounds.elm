module Evergreen.V124.Bounds exposing (..)

import Evergreen.V124.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V124.Coord.Coord unit
        , max : Evergreen.V124.Coord.Coord unit
        }
