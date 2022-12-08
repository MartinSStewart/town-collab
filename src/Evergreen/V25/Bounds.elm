module Evergreen.V25.Bounds exposing (..)

import Evergreen.V25.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V25.Coord.Coord unit
        , max : Evergreen.V25.Coord.Coord unit
        }
