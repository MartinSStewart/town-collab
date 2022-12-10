module Evergreen.V27.Grid exposing (..)

import Dict
import Evergreen.V27.Color
import Evergreen.V27.Coord
import Evergreen.V27.GridCell
import Evergreen.V27.Id
import Evergreen.V27.Tile
import Evergreen.V27.Units


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V27.GridCell.CellData)


type alias LocalGridChange =
    { position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
    , change : Evergreen.V27.Tile.Tile
    , primaryColor : Evergreen.V27.Color.Color
    , secondaryColor : Evergreen.V27.Color.Color
    }


type alias GridChange =
    { position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
    , change : Evergreen.V27.Tile.Tile
    , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , primaryColor : Evergreen.V27.Color.Color
    , secondaryColor : Evergreen.V27.Color.Color
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V27.GridCell.Cell)
