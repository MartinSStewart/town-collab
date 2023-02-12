module Evergreen.V62.Bounds exposing (..)

import Evergreen.V62.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V62.Coord.Coord unit
        , max : Evergreen.V62.Coord.Coord unit
        }
