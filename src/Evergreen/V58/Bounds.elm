module Evergreen.V58.Bounds exposing (..)

import Evergreen.V58.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V58.Coord.Coord unit
        , max : Evergreen.V58.Coord.Coord unit
        }
