module Evergreen.V29.GridCell exposing (..)

import Dict
import Evergreen.V29.Color
import Evergreen.V29.Coord
import Evergreen.V29.Id
import Evergreen.V29.Tile
import Evergreen.V29.Units


type alias Value =
    { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.CellLocalUnit
    , value : Evergreen.V29.Tile.Tile
    , primaryColor : Evergreen.V29.Color.Color
    , secondaryColor : Evergreen.V29.Color.Color
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
