module Evergreen.V76.Bounds exposing (..)

import Evergreen.V76.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V76.Coord.Coord unit
        , max : Evergreen.V76.Coord.Coord unit
        }
