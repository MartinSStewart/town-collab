module Evergreen.V75.GridCell exposing (..)

import AssocSet
import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.Id
import Evergreen.V75.IdDict
import Evergreen.V75.Tile
import Evergreen.V75.Units


type alias Value =
    { userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.CellLocalUnit
    , value : Evergreen.V75.Tile.Tile
    , colors : Evergreen.V75.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V75.Coord.Coord Evergreen.V75.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V75.Coord.Coord Evergreen.V75.Units.CellLocalUnit)
        }
