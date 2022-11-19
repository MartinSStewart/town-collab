module Evergreen.V2.GridCell exposing (..)

import Dict
import Evergreen.V2.Coord
import Evergreen.V2.Id
import Evergreen.V2.Tile
import Evergreen.V2.Units


type alias Value =
    { userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
    , position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.CellLocalUnit
    , value : Evergreen.V2.Tile.Tile
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
