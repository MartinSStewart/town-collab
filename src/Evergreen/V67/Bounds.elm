module Evergreen.V67.Bounds exposing (..)

import Evergreen.V67.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V67.Coord.Coord unit
        , max : Evergreen.V67.Coord.Coord unit
        }
