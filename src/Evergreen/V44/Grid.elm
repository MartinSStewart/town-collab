module Evergreen.V44.Grid exposing (..)

import Dict
import Evergreen.V44.Color
import Evergreen.V44.Coord
import Evergreen.V44.GridCell
import Evergreen.V44.Id
import Evergreen.V44.Tile
import Evergreen.V44.Units


type alias LocalGridChange =
    { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
    , change : Evergreen.V44.Tile.Tile
    , colors : Evergreen.V44.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
    , change : Evergreen.V44.Tile.Tile
    , userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    , colors : Evergreen.V44.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V44.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V44.GridCell.CellData)
