module Evergreen.V89.Grid exposing (..)

import Dict
import Evergreen.V89.Color
import Evergreen.V89.Coord
import Evergreen.V89.GridCell
import Evergreen.V89.Id
import Evergreen.V89.Tile
import Evergreen.V89.Units


type alias LocalGridChange =
    { position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    , change : Evergreen.V89.Tile.Tile
    , colors : Evergreen.V89.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    , change : Evergreen.V89.Tile.Tile
    , userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , colors : Evergreen.V89.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V89.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V89.GridCell.CellData)
