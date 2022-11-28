module Evergreen.V11.Grid exposing (..)

import Dict
import Evergreen.V11.Coord
import Evergreen.V11.GridCell
import Evergreen.V11.Id
import Evergreen.V11.Tile
import Evergreen.V11.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V11.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
    , change : Evergreen.V11.Tile.Tile
    }


type alias GridChange =
    { position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
    , change : Evergreen.V11.Tile.Tile
    , userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V11.GridCell.Cell)
