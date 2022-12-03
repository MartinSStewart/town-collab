module Evergreen.V17.Grid exposing (..)

import Dict
import Evergreen.V17.Color
import Evergreen.V17.Coord
import Evergreen.V17.GridCell
import Evergreen.V17.Id
import Evergreen.V17.Tile
import Evergreen.V17.Units


type GridData
    = GridData (Dict.Dict (Int, Int) Evergreen.V17.GridCell.CellData)


type alias LocalGridChange = 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , change : Evergreen.V17.Tile.Tile
    , primaryColor : Evergreen.V17.Color.Color
    , secondaryColor : Evergreen.V17.Color.Color
    }


type alias GridChange = 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , change : Evergreen.V17.Tile.Tile
    , userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , primaryColor : Evergreen.V17.Color.Color
    , secondaryColor : Evergreen.V17.Color.Color
    }


type Grid
    = Grid (Dict.Dict (Int, Int) Evergreen.V17.GridCell.Cell)