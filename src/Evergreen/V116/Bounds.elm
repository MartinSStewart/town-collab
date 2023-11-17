module Evergreen.V116.Bounds exposing (..)

import Evergreen.V116.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V116.Coord.Coord unit
        , max : Evergreen.V116.Coord.Coord unit
        }
