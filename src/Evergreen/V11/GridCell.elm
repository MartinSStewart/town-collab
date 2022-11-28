module Evergreen.V11.GridCell exposing (..)

import Dict
import Evergreen.V11.Coord
import Evergreen.V11.Id
import Evergreen.V11.Tile
import Evergreen.V11.Units


type alias Value =
    { userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
    , position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.CellLocalUnit
    , value : Evergreen.V11.Tile.Tile
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
