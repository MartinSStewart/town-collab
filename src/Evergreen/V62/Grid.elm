module Evergreen.V62.Grid exposing (..)

import Dict
import Evergreen.V62.Color
import Evergreen.V62.Coord
import Evergreen.V62.GridCell
import Evergreen.V62.Id
import Evergreen.V62.Tile
import Evergreen.V62.Units


type alias LocalGridChange =
    { position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
    , change : Evergreen.V62.Tile.Tile
    , colors : Evergreen.V62.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
    , change : Evergreen.V62.Tile.Tile
    , userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , colors : Evergreen.V62.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V62.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V62.GridCell.CellData)
