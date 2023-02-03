module Evergreen.V47.Grid exposing (..)

import Dict
import Evergreen.V47.Color
import Evergreen.V47.Coord
import Evergreen.V47.GridCell
import Evergreen.V47.Id
import Evergreen.V47.Tile
import Evergreen.V47.Units


type alias LocalGridChange =
    { position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
    , change : Evergreen.V47.Tile.Tile
    , colors : Evergreen.V47.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
    , change : Evergreen.V47.Tile.Tile
    , userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , colors : Evergreen.V47.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V47.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V47.GridCell.CellData)
