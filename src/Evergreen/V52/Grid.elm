module Evergreen.V52.Grid exposing (..)

import Dict
import Evergreen.V52.Color
import Evergreen.V52.Coord
import Evergreen.V52.GridCell
import Evergreen.V52.Id
import Evergreen.V52.Tile
import Evergreen.V52.Units


type alias LocalGridChange =
    { position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
    , change : Evergreen.V52.Tile.Tile
    , colors : Evergreen.V52.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
    , change : Evergreen.V52.Tile.Tile
    , userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , colors : Evergreen.V52.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V52.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V52.GridCell.CellData)
