module Evergreen.V111.Bounds exposing (..)

import Evergreen.V111.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V111.Coord.Coord unit
        , max : Evergreen.V111.Coord.Coord unit
        }
