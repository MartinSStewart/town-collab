module Evergreen.V82.GridCell exposing (..)

import AssocSet
import Evergreen.V82.Color
import Evergreen.V82.Coord
import Evergreen.V82.Id
import Evergreen.V82.IdDict
import Evergreen.V82.Tile
import Evergreen.V82.Units


type alias Value =
    { userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.CellLocalUnit
    , value : Evergreen.V82.Tile.Tile
    , colors : Evergreen.V82.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V82.Coord.Coord Evergreen.V82.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V82.Coord.Coord Evergreen.V82.Units.CellLocalUnit)
        }
