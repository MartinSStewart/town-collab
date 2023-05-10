module Evergreen.V76.Grid exposing (..)

import Dict
import Evergreen.V76.Color
import Evergreen.V76.Coord
import Evergreen.V76.GridCell
import Evergreen.V76.Id
import Evergreen.V76.Tile
import Evergreen.V76.Units


type alias LocalGridChange =
    { position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , change : Evergreen.V76.Tile.Tile
    , colors : Evergreen.V76.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , change : Evergreen.V76.Tile.Tile
    , userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , colors : Evergreen.V76.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V76.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V76.GridCell.CellData)
