module Evergreen.V24.GridCell exposing (..)

import Dict
import Evergreen.V24.Color
import Evergreen.V24.Coord
import Evergreen.V24.Id
import Evergreen.V24.Tile
import Evergreen.V24.Units


type alias Value =
    { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.CellLocalUnit
    , value : Evergreen.V24.Tile.Tile
    , primaryColor : Evergreen.V24.Color.Color
    , secondaryColor : Evergreen.V24.Color.Color
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
