module Evergreen.V54.Grid exposing (..)

import Dict
import Evergreen.V54.Color
import Evergreen.V54.Coord
import Evergreen.V54.GridCell
import Evergreen.V54.Tile
import Evergreen.V54.Units


type alias LocalGridChange =
    { position : Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit
    , change : Evergreen.V54.Tile.Tile
    , colors : Evergreen.V54.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V54.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V54.GridCell.CellData)
