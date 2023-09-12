module Evergreen.V84.Grid exposing (..)

import Dict
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.GridCell
import Evergreen.V84.Id
import Evergreen.V84.Tile
import Evergreen.V84.Units


type alias LocalGridChange =
    { position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , change : Evergreen.V84.Tile.Tile
    , colors : Evergreen.V84.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , change : Evergreen.V84.Tile.Tile
    , userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , colors : Evergreen.V84.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V84.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V84.GridCell.CellData)
