module Evergreen.V49.Grid exposing (..)

import Dict
import Evergreen.V49.Color
import Evergreen.V49.Coord
import Evergreen.V49.GridCell
import Evergreen.V49.Id
import Evergreen.V49.Tile
import Evergreen.V49.Units


type alias LocalGridChange =
    { position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
    , change : Evergreen.V49.Tile.Tile
    , colors : Evergreen.V49.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
    , change : Evergreen.V49.Tile.Tile
    , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , colors : Evergreen.V49.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V49.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V49.GridCell.CellData)
