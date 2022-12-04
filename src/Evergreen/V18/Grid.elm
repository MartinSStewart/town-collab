module Evergreen.V18.Grid exposing (..)

import Dict
import Evergreen.V18.Color
import Evergreen.V18.Coord
import Evergreen.V18.GridCell
import Evergreen.V18.Id
import Evergreen.V18.Tile
import Evergreen.V18.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V18.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
    , change : Evergreen.V18.Tile.Tile
    , primaryColor : Evergreen.V18.Color.Color
    , secondaryColor : Evergreen.V18.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
    , change : Evergreen.V18.Tile.Tile
    , userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    , primaryColor : Evergreen.V18.Color.Color
    , secondaryColor : Evergreen.V18.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V18.GridCell.Cell)
