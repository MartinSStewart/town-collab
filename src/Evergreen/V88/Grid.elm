module Evergreen.V88.Grid exposing (..)

import Dict
import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.GridCell
import Evergreen.V88.Id
import Evergreen.V88.Tile
import Evergreen.V88.Units


type alias LocalGridChange =
    { position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , change : Evergreen.V88.Tile.Tile
    , colors : Evergreen.V88.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , change : Evergreen.V88.Tile.Tile
    , userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , colors : Evergreen.V88.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V88.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V88.GridCell.CellData)
