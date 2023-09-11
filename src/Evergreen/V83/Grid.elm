module Evergreen.V83.Grid exposing (..)

import Dict
import Evergreen.V83.Color
import Evergreen.V83.Coord
import Evergreen.V83.GridCell
import Evergreen.V83.Id
import Evergreen.V83.Tile
import Evergreen.V83.Units


type alias LocalGridChange =
    { position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , change : Evergreen.V83.Tile.Tile
    , colors : Evergreen.V83.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , change : Evergreen.V83.Tile.Tile
    , userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , colors : Evergreen.V83.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V83.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V83.GridCell.CellData)
