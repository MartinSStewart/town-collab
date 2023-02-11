module Evergreen.V60.Grid exposing (..)

import Dict
import Evergreen.V60.Color
import Evergreen.V60.Coord
import Evergreen.V60.GridCell
import Evergreen.V60.Id
import Evergreen.V60.Tile
import Evergreen.V60.Units


type alias LocalGridChange =
    { position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
    , change : Evergreen.V60.Tile.Tile
    , colors : Evergreen.V60.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
    , change : Evergreen.V60.Tile.Tile
    , userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , colors : Evergreen.V60.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V60.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V60.GridCell.CellData)
