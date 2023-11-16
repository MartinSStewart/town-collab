module Evergreen.V115.Bounds exposing (..)

import Evergreen.V115.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V115.Coord.Coord unit
        , max : Evergreen.V115.Coord.Coord unit
        }
