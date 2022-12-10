module Evergreen.V27.GridCell exposing (..)

import Dict
import Evergreen.V27.Color
import Evergreen.V27.Coord
import Evergreen.V27.Id
import Evergreen.V27.Tile
import Evergreen.V27.Units


type alias Value =
    { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.CellLocalUnit
    , value : Evergreen.V27.Tile.Tile
    , primaryColor : Evergreen.V27.Color.Color
    , secondaryColor : Evergreen.V27.Color.Color
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
