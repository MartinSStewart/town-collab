module Evergreen.V134.Bounds exposing (..)

import Evergreen.V134.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V134.Coord.Coord unit
        , max : Evergreen.V134.Coord.Coord unit
        }
