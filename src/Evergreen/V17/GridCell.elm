module Evergreen.V17.GridCell exposing (..)

import Dict
import Evergreen.V17.Color
import Evergreen.V17.Coord
import Evergreen.V17.Id
import Evergreen.V17.Tile
import Evergreen.V17.Units


type alias Value = 
    { userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.CellLocalUnit)
    , value : Evergreen.V17.Tile.Tile
    , primaryColor : Evergreen.V17.Color.Color
    , secondaryColor : Evergreen.V17.Color.Color
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