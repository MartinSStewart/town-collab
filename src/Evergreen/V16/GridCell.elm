module Evergreen.V16.GridCell exposing (..)

import Dict
import Evergreen.V16.Coord
import Evergreen.V16.Id
import Evergreen.V16.Tile
import Evergreen.V16.Units


type alias Value =
    { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.CellLocalUnit
    , value : Evergreen.V16.Tile.Tile
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
