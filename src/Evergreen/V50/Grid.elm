module Evergreen.V50.Grid exposing (..)

import Dict
import Evergreen.V50.Color
import Evergreen.V50.Coord
import Evergreen.V50.GridCell
import Evergreen.V50.Id
import Evergreen.V50.Tile
import Evergreen.V50.Units


type alias LocalGridChange =
    { position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
    , change : Evergreen.V50.Tile.Tile
    , colors : Evergreen.V50.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
    , change : Evergreen.V50.Tile.Tile
    , userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , colors : Evergreen.V50.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V50.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V50.GridCell.CellData)
