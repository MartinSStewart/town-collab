module Evergreen.V56.Coord exposing (..)

import Quantity


type alias Coord units =
    ( Quantity.Quantity Int units, Quantity.Quantity Int units )


type alias RawCellCoord =
    ( Int, Int )
