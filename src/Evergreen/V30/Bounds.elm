module Evergreen.V30.Bounds exposing (..)

import Evergreen.V30.Coord


type Bounds unit
    = Bounds 
    { min : (Evergreen.V30.Coord.Coord unit)
    , max : (Evergreen.V30.Coord.Coord unit)
    }