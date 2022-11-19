module Evergreen.V2.Grid exposing (..)

import Dict
import Evergreen.V2.Coord
import Evergreen.V2.GridCell
import Evergreen.V2.Id
import Evergreen.V2.Tile
import Evergreen.V2.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V2.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
    , change : Evergreen.V2.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
    , change : Evergreen.V2.Tile.Tile
    , userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V2.GridCell.Cell)
