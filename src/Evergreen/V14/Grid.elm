module Evergreen.V14.Grid exposing (..)

import Dict
import Evergreen.V14.Coord
import Evergreen.V14.GridCell
import Evergreen.V14.Id
import Evergreen.V14.Tile
import Evergreen.V14.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V14.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
    , change : Evergreen.V14.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
    , change : Evergreen.V14.Tile.Tile
    , userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V14.GridCell.Cell)
