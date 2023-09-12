module Evergreen.V84.Bounds exposing (..)

import Evergreen.V84.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V84.Coord.Coord unit
        , max : Evergreen.V84.Coord.Coord unit
        }
