module Evergreen.V42.Grid exposing (..)

import Dict
import Evergreen.V42.Color
import Evergreen.V42.Coord
import Evergreen.V42.GridCell
import Evergreen.V42.Id
import Evergreen.V42.Tile
import Evergreen.V42.Units


type alias LocalGridChange =
    { position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
    , change : Evergreen.V42.Tile.Tile
    , colors : Evergreen.V42.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
    , change : Evergreen.V42.Tile.Tile
    , userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , colors : Evergreen.V42.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V42.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V42.GridCell.CellData)
