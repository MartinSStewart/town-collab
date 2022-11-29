module Evergreen.V12.Bounds exposing (..)

import Evergreen.V12.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V12.Coord.Coord unit
        , max : Evergreen.V12.Coord.Coord unit
        }
