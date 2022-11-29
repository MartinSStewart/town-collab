module Evergreen.V14.Bounds exposing (..)

import Evergreen.V14.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V14.Coord.Coord unit
        , max : Evergreen.V14.Coord.Coord unit
        }
