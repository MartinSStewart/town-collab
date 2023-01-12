module Evergreen.V33.Bounds exposing (..)

import Evergreen.V33.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V33.Coord.Coord unit
        , max : Evergreen.V33.Coord.Coord unit
        }
