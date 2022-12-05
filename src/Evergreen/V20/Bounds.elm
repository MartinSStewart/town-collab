module Evergreen.V20.Bounds exposing (..)

import Evergreen.V20.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V20.Coord.Coord unit
        , max : Evergreen.V20.Coord.Coord unit
        }
