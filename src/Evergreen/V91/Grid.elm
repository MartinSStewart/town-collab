module Evergreen.V91.Grid exposing (..)

import Dict
import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.GridCell
import Evergreen.V91.Id
import Evergreen.V91.Tile
import Evergreen.V91.Units


type alias LocalGridChange =
    { position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , change : Evergreen.V91.Tile.Tile
    , colors : Evergreen.V91.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , change : Evergreen.V91.Tile.Tile
    , userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , colors : Evergreen.V91.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V91.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V91.GridCell.CellData)
