module Evergreen.V15.GridCell exposing (..)

import Dict
import Evergreen.V15.Coord
import Evergreen.V15.Id
import Evergreen.V15.Tile
import Evergreen.V15.Units


type alias Value =
    { userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.CellLocalUnit
    , value : Evergreen.V15.Tile.Tile
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
