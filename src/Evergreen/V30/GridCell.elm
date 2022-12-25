module Evergreen.V30.GridCell exposing (..)

import Dict
import Evergreen.V30.Color
import Evergreen.V30.Coord
import Evergreen.V30.Id
import Evergreen.V30.Tile
import Evergreen.V30.Units


type alias Value = 
    { userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.CellLocalUnit)
    , value : Evergreen.V30.Tile.Tile
    , colors : Evergreen.V30.Color.Colors
    }


type CellData
    = CellData 
    { history : (List Value)
    , undoPoint : (Dict.Dict Int Int)
    }


type Cell
    = Cell 
    { history : (List Value)
    , undoPoint : (Dict.Dict Int Int)
    , cache : (List Value)
    }