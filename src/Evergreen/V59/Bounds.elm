module Evergreen.V59.Bounds exposing (..)

import Evergreen.V59.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V59.Coord.Coord unit
        , max : Evergreen.V59.Coord.Coord unit
        }
