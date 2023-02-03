module Evergreen.V44.Bounds exposing (..)

import Evergreen.V44.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V44.Coord.Coord unit
        , max : Evergreen.V44.Coord.Coord unit
        }
