module Evergreen.V2.Bounds exposing (..)

import Evergreen.V2.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V2.Coord.Coord unit
        , max : Evergreen.V2.Coord.Coord unit
        }
