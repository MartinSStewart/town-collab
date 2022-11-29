module Evergreen.V15.Grid exposing (..)

import Dict
import Evergreen.V15.Coord
import Evergreen.V15.GridCell
import Evergreen.V15.Id
import Evergreen.V15.Tile
import Evergreen.V15.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V15.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
    , change : Evergreen.V15.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
    , change : Evergreen.V15.Tile.Tile
    , userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V15.GridCell.Cell)
