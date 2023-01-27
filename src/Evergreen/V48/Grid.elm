module Evergreen.V48.Grid exposing (..)

import Dict
import Evergreen.V48.Color
import Evergreen.V48.Coord
import Evergreen.V48.GridCell
import Evergreen.V48.Id
import Evergreen.V48.Tile
import Evergreen.V48.Units


type alias LocalGridChange =
    { position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
    , change : Evergreen.V48.Tile.Tile
    , colors : Evergreen.V48.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
    , change : Evergreen.V48.Tile.Tile
    , userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , colors : Evergreen.V48.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V48.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V48.GridCell.CellData)
