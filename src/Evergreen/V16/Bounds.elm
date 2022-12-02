module Evergreen.V16.Bounds exposing (..)

import Evergreen.V16.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V16.Coord.Coord unit
        , max : Evergreen.V16.Coord.Coord unit
        }
