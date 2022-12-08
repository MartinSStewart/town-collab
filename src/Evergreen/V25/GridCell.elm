module Evergreen.V25.GridCell exposing (..)

import Dict
import Evergreen.V25.Color
import Evergreen.V25.Coord
import Evergreen.V25.Id
import Evergreen.V25.Tile
import Evergreen.V25.Units


type alias Value =
    { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.CellLocalUnit
    , value : Evergreen.V25.Tile.Tile
    , primaryColor : Evergreen.V25.Color.Color
    , secondaryColor : Evergreen.V25.Color.Color
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
