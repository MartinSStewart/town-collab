module Evergreen.V9.Grid exposing (..)

import Dict
import Evergreen.V9.Coord
import Evergreen.V9.GridCell
import Evergreen.V9.Id
import Evergreen.V9.Tile
import Evergreen.V9.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V9.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , change : Evergreen.V9.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , change : Evergreen.V9.Tile.Tile
    , userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V9.GridCell.Cell)
