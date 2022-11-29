module Evergreen.V14.GridCell exposing (..)

import Dict
import Evergreen.V14.Coord
import Evergreen.V14.Id
import Evergreen.V14.Tile
import Evergreen.V14.Units


type alias Value =
    { userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.CellLocalUnit
    , value : Evergreen.V14.Tile.Tile
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
