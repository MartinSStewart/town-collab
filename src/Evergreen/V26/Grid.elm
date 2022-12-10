module Evergreen.V26.Grid exposing (..)

import Dict
import Evergreen.V26.Color
import Evergreen.V26.Coord
import Evergreen.V26.GridCell
import Evergreen.V26.Id
import Evergreen.V26.Tile
import Evergreen.V26.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V26.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
    , change : Evergreen.V26.Tile.Tile
    , primaryColor : Evergreen.V26.Color.Color
    , secondaryColor : Evergreen.V26.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
    , change : Evergreen.V26.Tile.Tile
    , userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , primaryColor : Evergreen.V26.Color.Color
    , secondaryColor : Evergreen.V26.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V26.GridCell.Cell)
