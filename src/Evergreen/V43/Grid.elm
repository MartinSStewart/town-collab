module Evergreen.V43.Grid exposing (..)

import Dict
import Evergreen.V43.Color
import Evergreen.V43.Coord
import Evergreen.V43.GridCell
import Evergreen.V43.Id
import Evergreen.V43.Tile
import Evergreen.V43.Units


type alias LocalGridChange =
    { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
    , change : Evergreen.V43.Tile.Tile
    , colors : Evergreen.V43.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
    , change : Evergreen.V43.Tile.Tile
    , userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    , colors : Evergreen.V43.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V43.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V43.GridCell.CellData)
