module Evergreen.V23.Grid exposing (..)

import Dict
import Evergreen.V23.Color
import Evergreen.V23.Coord
import Evergreen.V23.GridCell
import Evergreen.V23.Id
import Evergreen.V23.Tile
import Evergreen.V23.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V23.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
    , change : Evergreen.V23.Tile.Tile
    , primaryColor : Evergreen.V23.Color.Color
    , secondaryColor : Evergreen.V23.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
    , change : Evergreen.V23.Tile.Tile
    , userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , primaryColor : Evergreen.V23.Color.Color
    , secondaryColor : Evergreen.V23.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V23.GridCell.Cell)
