module Evergreen.V50.Bounds exposing (..)

import Evergreen.V50.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V50.Coord.Coord unit
        , max : Evergreen.V50.Coord.Coord unit
        }
