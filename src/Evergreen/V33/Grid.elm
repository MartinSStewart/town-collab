module Evergreen.V33.Grid exposing (..)

import Dict
import Evergreen.V33.Color
import Evergreen.V33.Coord
import Evergreen.V33.GridCell
import Evergreen.V33.Id
import Evergreen.V33.Tile
import Evergreen.V33.Units


type alias LocalGridChange =
    { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
    , change : Evergreen.V33.Tile.Tile
    , colors : Evergreen.V33.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
    , change : Evergreen.V33.Tile.Tile
    , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , colors : Evergreen.V33.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V33.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V33.GridCell.CellData)
