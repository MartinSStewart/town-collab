module Evergreen.V18.GridCell exposing (..)

import Dict
import Evergreen.V18.Color
import Evergreen.V18.Coord
import Evergreen.V18.Id
import Evergreen.V18.Tile
import Evergreen.V18.Units


type alias Value =
    { userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    , position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.CellLocalUnit
    , value : Evergreen.V18.Tile.Tile
    , primaryColor : Evergreen.V18.Color.Color
    , secondaryColor : Evergreen.V18.Color.Color
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
