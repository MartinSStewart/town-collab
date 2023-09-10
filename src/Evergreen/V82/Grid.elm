module Evergreen.V82.Grid exposing (..)

import Dict
import Evergreen.V82.Color
import Evergreen.V82.Coord
import Evergreen.V82.GridCell
import Evergreen.V82.Id
import Evergreen.V82.Tile
import Evergreen.V82.Units


type alias LocalGridChange =
    { position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , change : Evergreen.V82.Tile.Tile
    , colors : Evergreen.V82.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , change : Evergreen.V82.Tile.Tile
    , userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , colors : Evergreen.V82.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V82.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V82.GridCell.CellData)
