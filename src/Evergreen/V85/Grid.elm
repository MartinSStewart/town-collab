module Evergreen.V85.Grid exposing (..)

import Dict
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.GridCell
import Evergreen.V85.Id
import Evergreen.V85.Tile
import Evergreen.V85.Units


type alias LocalGridChange =
    { position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , change : Evergreen.V85.Tile.Tile
    , colors : Evergreen.V85.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , change : Evergreen.V85.Tile.Tile
    , userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , colors : Evergreen.V85.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V85.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V85.GridCell.CellData)
