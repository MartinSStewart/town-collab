module Evergreen.V58.Grid exposing (..)

import Dict
import Evergreen.V58.Color
import Evergreen.V58.Coord
import Evergreen.V58.GridCell
import Evergreen.V58.Id
import Evergreen.V58.Tile
import Evergreen.V58.Units


type alias LocalGridChange =
    { position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
    , change : Evergreen.V58.Tile.Tile
    , colors : Evergreen.V58.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
    , change : Evergreen.V58.Tile.Tile
    , userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , colors : Evergreen.V58.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V58.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V58.GridCell.CellData)
