module Evergreen.V25.Grid exposing (..)

import Dict
import Evergreen.V25.Color
import Evergreen.V25.Coord
import Evergreen.V25.GridCell
import Evergreen.V25.Id
import Evergreen.V25.Tile
import Evergreen.V25.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V25.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
    , change : Evergreen.V25.Tile.Tile
    , primaryColor : Evergreen.V25.Color.Color
    , secondaryColor : Evergreen.V25.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
    , change : Evergreen.V25.Tile.Tile
    , userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , primaryColor : Evergreen.V25.Color.Color
    , secondaryColor : Evergreen.V25.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V25.GridCell.Cell)
