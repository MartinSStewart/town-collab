module Evergreen.V44.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V44.Color
import Evergreen.V44.Coord
import Evergreen.V44.Id
import Evergreen.V44.Tile
import Evergreen.V44.Units


type alias Value =
    { userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    , position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.CellLocalUnit
    , value : Evergreen.V44.Tile.Tile
    , colors : Evergreen.V44.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V44.Coord.Coord Evergreen.V44.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V44.Coord.Coord Evergreen.V44.Units.CellLocalUnit)
        }
