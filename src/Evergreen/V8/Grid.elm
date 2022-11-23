module Evergreen.V8.Grid exposing (..)

import Dict
import Evergreen.V8.Coord
import Evergreen.V8.GridCell
import Evergreen.V8.Id
import Evergreen.V8.Tile
import Evergreen.V8.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V8.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    , change : Evergreen.V8.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    , change : Evergreen.V8.Tile.Tile
    , userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V8.GridCell.Cell)
