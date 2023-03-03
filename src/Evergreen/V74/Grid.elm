module Evergreen.V74.Grid exposing (..)

import Dict
import Evergreen.V74.Color
import Evergreen.V74.Coord
import Evergreen.V74.GridCell
import Evergreen.V74.Id
import Evergreen.V74.Tile
import Evergreen.V74.Units


type alias LocalGridChange =
    { position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , change : Evergreen.V74.Tile.Tile
    , colors : Evergreen.V74.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , change : Evergreen.V74.Tile.Tile
    , userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , colors : Evergreen.V74.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V74.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V74.GridCell.CellData)
