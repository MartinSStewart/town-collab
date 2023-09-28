module Evergreen.V89.Bounds exposing (..)

import Evergreen.V89.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V89.Coord.Coord unit
        , max : Evergreen.V89.Coord.Coord unit
        }
