module Evergreen.V69.Grid exposing (..)

import Dict
import Evergreen.V69.Color
import Evergreen.V69.Coord
import Evergreen.V69.GridCell
import Evergreen.V69.Id
import Evergreen.V69.Tile
import Evergreen.V69.Units


type alias LocalGridChange =
    { position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    , change : Evergreen.V69.Tile.Tile
    , colors : Evergreen.V69.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    , change : Evergreen.V69.Tile.Tile
    , userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , colors : Evergreen.V69.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V69.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V69.GridCell.CellData)
