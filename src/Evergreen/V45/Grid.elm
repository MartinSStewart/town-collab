module Evergreen.V45.Grid exposing (..)

import Dict
import Evergreen.V45.Color
import Evergreen.V45.Coord
import Evergreen.V45.GridCell
import Evergreen.V45.Id
import Evergreen.V45.Tile
import Evergreen.V45.Units


type alias LocalGridChange =
    { position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
    , change : Evergreen.V45.Tile.Tile
    , colors : Evergreen.V45.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
    , change : Evergreen.V45.Tile.Tile
    , userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , colors : Evergreen.V45.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V45.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V45.GridCell.CellData)
