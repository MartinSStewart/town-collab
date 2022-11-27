module Evergreen.V10.GridCell exposing (..)

import Dict
import Evergreen.V10.Coord
import Evergreen.V10.Id
import Evergreen.V10.Tile
import Evergreen.V10.Units


type alias Value =
    { userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
    , position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.CellLocalUnit
    , value : Evergreen.V10.Tile.Tile
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
