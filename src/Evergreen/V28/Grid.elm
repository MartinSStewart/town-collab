module Evergreen.V28.Grid exposing (..)

import Dict
import Evergreen.V28.Color
import Evergreen.V28.Coord
import Evergreen.V28.GridCell
import Evergreen.V28.Id
import Evergreen.V28.Tile
import Evergreen.V28.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V28.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
    , change : Evergreen.V28.Tile.Tile
    , primaryColor : Evergreen.V28.Color.Color
    , secondaryColor : Evergreen.V28.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
    , change : Evergreen.V28.Tile.Tile
    , userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
    , primaryColor : Evergreen.V28.Color.Color
    , secondaryColor : Evergreen.V28.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V28.GridCell.Cell)
