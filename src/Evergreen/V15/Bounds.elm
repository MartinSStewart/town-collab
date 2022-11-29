module Evergreen.V15.Bounds exposing (..)

import Evergreen.V15.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V15.Coord.Coord unit
        , max : Evergreen.V15.Coord.Coord unit
        }
