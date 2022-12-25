module Evergreen.V30.Grid exposing (..)

import Dict
import Evergreen.V30.Color
import Evergreen.V30.Coord
import Evergreen.V30.GridCell
import Evergreen.V30.Id
import Evergreen.V30.Tile
import Evergreen.V30.Units


type alias LocalGridChange = 
    { position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , change : Evergreen.V30.Tile.Tile
    , colors : Evergreen.V30.Color.Colors
    }


type alias GridChange = 
    { position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , change : Evergreen.V30.Tile.Tile
    , userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , colors : Evergreen.V30.Color.Colors
    }


type Grid
    = Grid (Dict.Dict (Int, Int) Evergreen.V30.GridCell.Cell)


type GridData
    = GridData (Dict.Dict (Int, Int) Evergreen.V30.GridCell.CellData)