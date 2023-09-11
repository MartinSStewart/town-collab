module Evergreen.V83.Bounds exposing (..)

import Evergreen.V83.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V83.Coord.Coord unit
        , max : Evergreen.V83.Coord.Coord unit
        }
