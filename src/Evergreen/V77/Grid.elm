module Evergreen.V77.Grid exposing (..)

import Dict
import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.GridCell
import Evergreen.V77.Id
import Evergreen.V77.Tile
import Evergreen.V77.Units


type alias LocalGridChange =
    { position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , change : Evergreen.V77.Tile.Tile
    , colors : Evergreen.V77.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , change : Evergreen.V77.Tile.Tile
    , userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , colors : Evergreen.V77.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V77.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V77.GridCell.CellData)
