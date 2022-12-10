module Evergreen.V26.Bounds exposing (..)

import Evergreen.V26.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V26.Coord.Coord unit
        , max : Evergreen.V26.Coord.Coord unit
        }
