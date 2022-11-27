module Evergreen.V10.Grid exposing (..)

import Dict
import Evergreen.V10.Coord
import Evergreen.V10.GridCell
import Evergreen.V10.Id
import Evergreen.V10.Tile
import Evergreen.V10.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V10.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
    , change : Evergreen.V10.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
    , change : Evergreen.V10.Tile.Tile
    , userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V10.GridCell.Cell)
