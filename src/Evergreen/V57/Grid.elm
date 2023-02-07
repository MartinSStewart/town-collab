module Evergreen.V57.Grid exposing (..)

import Dict
import Evergreen.V57.Color
import Evergreen.V57.Coord
import Evergreen.V57.GridCell
import Evergreen.V57.Id
import Evergreen.V57.Tile
import Evergreen.V57.Units


type alias LocalGridChange =
    { position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
    , change : Evergreen.V57.Tile.Tile
    , colors : Evergreen.V57.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
    , change : Evergreen.V57.Tile.Tile
    , userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , colors : Evergreen.V57.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V57.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V57.GridCell.CellData)
