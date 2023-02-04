module Evergreen.V56.Grid exposing (..)

import Dict
import Evergreen.V56.Color
import Evergreen.V56.Coord
import Evergreen.V56.GridCell
import Evergreen.V56.Id
import Evergreen.V56.Tile
import Evergreen.V56.Units


type alias LocalGridChange =
    { position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
    , change : Evergreen.V56.Tile.Tile
    , colors : Evergreen.V56.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
    , change : Evergreen.V56.Tile.Tile
    , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , colors : Evergreen.V56.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V56.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V56.GridCell.CellData)
