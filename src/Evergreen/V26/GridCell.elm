module Evergreen.V26.GridCell exposing (..)

import Dict
import Evergreen.V26.Color
import Evergreen.V26.Coord
import Evergreen.V26.Id
import Evergreen.V26.Tile
import Evergreen.V26.Units


type alias Value =
    { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.CellLocalUnit
    , value : Evergreen.V26.Tile.Tile
    , primaryColor : Evergreen.V26.Color.Color
    , secondaryColor : Evergreen.V26.Color.Color
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
