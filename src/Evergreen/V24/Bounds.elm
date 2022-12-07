module Evergreen.V24.Bounds exposing (..)

import Evergreen.V24.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V24.Coord.Coord unit
        , max : Evergreen.V24.Coord.Coord unit
        }
