module Evergreen.V75.Bounds exposing (..)

import Evergreen.V75.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V75.Coord.Coord unit
        , max : Evergreen.V75.Coord.Coord unit
        }
