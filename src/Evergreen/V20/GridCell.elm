module Evergreen.V20.GridCell exposing (..)

import Dict
import Evergreen.V20.Color
import Evergreen.V20.Coord
import Evergreen.V20.Id
import Evergreen.V20.Tile
import Evergreen.V20.Units


type alias Value =
    { userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
    , position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.CellLocalUnit
    , value : Evergreen.V20.Tile.Tile
    , primaryColor : Evergreen.V20.Color.Color
    , secondaryColor : Evergreen.V20.Color.Color
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
