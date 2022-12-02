module Evergreen.V16.Grid exposing (..)

import Dict
import Evergreen.V16.Coord
import Evergreen.V16.GridCell
import Evergreen.V16.Id
import Evergreen.V16.Tile
import Evergreen.V16.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V16.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
    , change : Evergreen.V16.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
    , change : Evergreen.V16.Tile.Tile
    , userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V16.GridCell.Cell)
