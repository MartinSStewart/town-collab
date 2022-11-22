module Evergreen.V6.GridCell exposing (..)

import Dict
import Evergreen.V6.Coord
import Evergreen.V6.Id
import Evergreen.V6.Tile
import Evergreen.V6.Units


type alias Value =
    { userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
    , position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.CellLocalUnit
    , value : Evergreen.V6.Tile.Tile
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
