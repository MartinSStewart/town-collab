module Evergreen.V67.Grid exposing (..)

import Dict
import Evergreen.V67.Color
import Evergreen.V67.Coord
import Evergreen.V67.GridCell
import Evergreen.V67.Id
import Evergreen.V67.Tile
import Evergreen.V67.Units


type alias LocalGridChange =
    { position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
    , change : Evergreen.V67.Tile.Tile
    , colors : Evergreen.V67.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
    , change : Evergreen.V67.Tile.Tile
    , userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , colors : Evergreen.V67.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V67.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V67.GridCell.CellData)
