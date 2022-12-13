module Evergreen.V29.Grid exposing (..)

import Dict
import Evergreen.V29.Color
import Evergreen.V29.Coord
import Evergreen.V29.GridCell
import Evergreen.V29.Id
import Evergreen.V29.Tile
import Evergreen.V29.Units


type alias LocalGridChange =
    { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
    , change : Evergreen.V29.Tile.Tile
    , primaryColor : Evergreen.V29.Color.Color
    , secondaryColor : Evergreen.V29.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
    , change : Evergreen.V29.Tile.Tile
    , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , primaryColor : Evergreen.V29.Color.Color
    , secondaryColor : Evergreen.V29.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V29.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V29.GridCell.CellData)
