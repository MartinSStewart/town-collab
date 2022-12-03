module Evergreen.V17.Bounds exposing (..)

import Evergreen.V17.Coord


type Bounds unit
    = Bounds 
    { min : (Evergreen.V17.Coord.Coord unit)
    , max : (Evergreen.V17.Coord.Coord unit)
    }