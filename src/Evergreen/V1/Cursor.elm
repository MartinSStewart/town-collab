module Evergreen.V1.Cursor exposing (..)

import Evergreen.V1.Coord
import Evergreen.V1.Units
import Quantity


type Cursor
    = Cursor
        { position : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
        , startingColumn : Quantity.Quantity Int Evergreen.V1.Units.AsciiUnit
        , size : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
        }
