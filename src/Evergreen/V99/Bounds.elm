module Evergreen.V99.Bounds exposing (..)

import Evergreen.V99.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V99.Coord.Coord unit
        , max : Evergreen.V99.Coord.Coord unit
        }
