module Evergreen.V9.GridCell exposing (..)

import Dict
import Evergreen.V9.Coord
import Evergreen.V9.Id
import Evergreen.V9.Tile
import Evergreen.V9.Units


type alias Value =
    { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.CellLocalUnit
    , value : Evergreen.V9.Tile.Tile
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
