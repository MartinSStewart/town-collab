module Evergreen.V6.Bounds exposing (..)

import Evergreen.V6.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V6.Coord.Coord unit
        , max : Evergreen.V6.Coord.Coord unit
        }
