module Evergreen.V113.Bounds exposing (..)

import Evergreen.V113.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V113.Coord.Coord unit
        , max : Evergreen.V113.Coord.Coord unit
        }
