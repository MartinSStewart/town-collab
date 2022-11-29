module Evergreen.V12.GridCell exposing (..)

import Dict
import Evergreen.V12.Coord
import Evergreen.V12.Id
import Evergreen.V12.Tile
import Evergreen.V12.Units


type alias Value =
    { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.CellLocalUnit
    , value : Evergreen.V12.Tile.Tile
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
