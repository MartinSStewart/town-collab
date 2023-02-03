module Evergreen.V46.Grid exposing (..)

import Dict
import Evergreen.V46.Color
import Evergreen.V46.Coord
import Evergreen.V46.GridCell
import Evergreen.V46.Id
import Evergreen.V46.Tile
import Evergreen.V46.Units


type alias LocalGridChange =
    { position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
    , change : Evergreen.V46.Tile.Tile
    , colors : Evergreen.V46.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
    , change : Evergreen.V46.Tile.Tile
    , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , colors : Evergreen.V46.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V46.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V46.GridCell.CellData)
