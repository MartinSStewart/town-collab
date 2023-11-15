module Evergreen.V114.Bounds exposing (..)

import Evergreen.V114.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V114.Coord.Coord unit
        , max : Evergreen.V114.Coord.Coord unit
        }
