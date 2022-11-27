module Evergreen.V10.Bounds exposing (..)

import Evergreen.V10.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V10.Coord.Coord unit
        , max : Evergreen.V10.Coord.Coord unit
        }
