module Evergreen.V23.GridCell exposing (..)

import Dict
import Evergreen.V23.Color
import Evergreen.V23.Coord
import Evergreen.V23.Id
import Evergreen.V23.Tile
import Evergreen.V23.Units


type alias Value =
    { userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.CellLocalUnit
    , value : Evergreen.V23.Tile.Tile
    , primaryColor : Evergreen.V23.Color.Color
    , secondaryColor : Evergreen.V23.Color.Color
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
