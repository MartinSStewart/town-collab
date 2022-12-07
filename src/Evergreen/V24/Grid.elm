module Evergreen.V24.Grid exposing (..)

import Dict
import Evergreen.V24.Color
import Evergreen.V24.Coord
import Evergreen.V24.GridCell
import Evergreen.V24.Id
import Evergreen.V24.Tile
import Evergreen.V24.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V24.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
    , change : Evergreen.V24.Tile.Tile
    , primaryColor : Evergreen.V24.Color.Color
    , secondaryColor : Evergreen.V24.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
    , change : Evergreen.V24.Tile.Tile
    , userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , primaryColor : Evergreen.V24.Color.Color
    , secondaryColor : Evergreen.V24.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V24.GridCell.Cell)
