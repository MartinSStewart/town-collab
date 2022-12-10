module Evergreen.V28.GridCell exposing (..)

import Dict
import Evergreen.V28.Color
import Evergreen.V28.Coord
import Evergreen.V28.Id
import Evergreen.V28.Tile
import Evergreen.V28.Units


type alias Value =
    { userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
    , position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.CellLocalUnit
    , value : Evergreen.V28.Tile.Tile
    , primaryColor : Evergreen.V28.Color.Color
    , secondaryColor : Evergreen.V28.Color.Color
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        }
