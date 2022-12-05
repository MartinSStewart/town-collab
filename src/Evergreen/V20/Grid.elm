module Evergreen.V20.Grid exposing (..)

import Dict
import Evergreen.V20.Color
import Evergreen.V20.Coord
import Evergreen.V20.GridCell
import Evergreen.V20.Id
import Evergreen.V20.Tile
import Evergreen.V20.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V20.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
    , change : Evergreen.V20.Tile.Tile
    , primaryColor : Evergreen.V20.Color.Color
    , secondaryColor : Evergreen.V20.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
    , change : Evergreen.V20.Tile.Tile
    , userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
    , primaryColor : Evergreen.V20.Color.Color
    , secondaryColor : Evergreen.V20.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V20.GridCell.Cell)
