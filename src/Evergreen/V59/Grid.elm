module Evergreen.V59.Grid exposing (..)

import Dict
import Evergreen.V59.Color
import Evergreen.V59.Coord
import Evergreen.V59.GridCell
import Evergreen.V59.Id
import Evergreen.V59.Tile
import Evergreen.V59.Units


type alias LocalGridChange =
    { position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
    , change : Evergreen.V59.Tile.Tile
    , colors : Evergreen.V59.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
    , change : Evergreen.V59.Tile.Tile
    , userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , colors : Evergreen.V59.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V59.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V59.GridCell.CellData)
