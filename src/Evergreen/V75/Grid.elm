module Evergreen.V75.Grid exposing (..)

import Dict
import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.GridCell
import Evergreen.V75.Id
import Evergreen.V75.Tile
import Evergreen.V75.Units


type alias LocalGridChange =
    { position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , change : Evergreen.V75.Tile.Tile
    , colors : Evergreen.V75.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , change : Evergreen.V75.Tile.Tile
    , userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , colors : Evergreen.V75.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V75.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V75.GridCell.CellData)
