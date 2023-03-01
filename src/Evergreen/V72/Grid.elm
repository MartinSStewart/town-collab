module Evergreen.V72.Grid exposing (..)

import Dict
import Evergreen.V72.Color
import Evergreen.V72.Coord
import Evergreen.V72.GridCell
import Evergreen.V72.Id
import Evergreen.V72.Tile
import Evergreen.V72.Units


type alias LocalGridChange =
    { position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , change : Evergreen.V72.Tile.Tile
    , colors : Evergreen.V72.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , change : Evergreen.V72.Tile.Tile
    , userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , colors : Evergreen.V72.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V72.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V72.GridCell.CellData)
