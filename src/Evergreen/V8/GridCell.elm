module Evergreen.V8.GridCell exposing (..)

import Dict
import Evergreen.V8.Coord
import Evergreen.V8.Id
import Evergreen.V8.Tile
import Evergreen.V8.Units


type alias Value =
    { userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
    , position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.CellLocalUnit
    , value : Evergreen.V8.Tile.Tile
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
