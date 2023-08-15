module Evergreen.V77.GridCell exposing (..)

import AssocSet
import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.Id
import Evergreen.V77.IdDict
import Evergreen.V77.Tile
import Evergreen.V77.Units


type alias Value =
    { userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.CellLocalUnit
    , value : Evergreen.V77.Tile.Tile
    , colors : Evergreen.V77.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V77.Coord.Coord Evergreen.V77.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V77.Coord.Coord Evergreen.V77.Units.CellLocalUnit)
        }
