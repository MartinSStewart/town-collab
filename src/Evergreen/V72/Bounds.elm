module Evergreen.V72.Bounds exposing (..)

import Evergreen.V72.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V72.Coord.Coord unit
        , max : Evergreen.V72.Coord.Coord unit
        }
