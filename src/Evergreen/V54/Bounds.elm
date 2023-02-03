module Evergreen.V54.Bounds exposing (..)

import Evergreen.V54.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V54.Coord.Coord unit
        , max : Evergreen.V54.Coord.Coord unit
        }
