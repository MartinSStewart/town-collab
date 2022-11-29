module Evergreen.V12.Grid exposing (..)

import Dict
import Evergreen.V12.Coord
import Evergreen.V12.GridCell
import Evergreen.V12.Id
import Evergreen.V12.Tile
import Evergreen.V12.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V12.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
    , change : Evergreen.V12.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
    , change : Evergreen.V12.Tile.Tile
    , userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V12.GridCell.Cell)
