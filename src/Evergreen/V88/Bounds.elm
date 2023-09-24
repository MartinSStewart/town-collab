module Evergreen.V88.Bounds exposing (..)

import Evergreen.V88.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V88.Coord.Coord unit
        , max : Evergreen.V88.Coord.Coord unit
        }
