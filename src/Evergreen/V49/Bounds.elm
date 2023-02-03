module Evergreen.V49.Bounds exposing (..)

import Evergreen.V49.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V49.Coord.Coord unit
        , max : Evergreen.V49.Coord.Coord unit
        }
