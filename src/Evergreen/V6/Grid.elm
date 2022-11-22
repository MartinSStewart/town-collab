module Evergreen.V6.Grid exposing (..)

import Dict
import Evergreen.V6.Coord
import Evergreen.V6.GridCell
import Evergreen.V6.Id
import Evergreen.V6.Tile
import Evergreen.V6.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V6.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    , change : Evergreen.V6.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    , change : Evergreen.V6.Tile.Tile
    , userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V6.GridCell.Cell)
