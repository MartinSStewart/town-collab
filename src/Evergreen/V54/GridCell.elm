module Evergreen.V54.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V54.Color
import Evergreen.V54.Coord
import Evergreen.V54.Id
import Evergreen.V54.Tile
import Evergreen.V54.Units


type alias Value =
    { userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , position : Evergreen.V54.Coord.Coord Evergreen.V54.Units.CellLocalUnit
    , value : Evergreen.V54.Tile.Tile
    , colors : Evergreen.V54.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V54.Coord.Coord Evergreen.V54.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V54.Coord.Coord Evergreen.V54.Units.CellLocalUnit)
        }
