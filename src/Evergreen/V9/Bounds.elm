module Evergreen.V9.Bounds exposing (..)

import Evergreen.V9.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V9.Coord.Coord unit
        , max : Evergreen.V9.Coord.Coord unit
        }
