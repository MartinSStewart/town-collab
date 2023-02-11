module Evergreen.V60.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V60.Color
import Evergreen.V60.Coord
import Evergreen.V60.Id
import Evergreen.V60.Tile
import Evergreen.V60.Units


type alias Value =
    { userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.CellLocalUnit
    , value : Evergreen.V60.Tile.Tile
    , colors : Evergreen.V60.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V60.Coord.Coord Evergreen.V60.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V60.Coord.Coord Evergreen.V60.Units.CellLocalUnit)
        }
