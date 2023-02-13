module Evergreen.V67.GridCell exposing (..)

import AssocSet
import Evergreen.V67.Color
import Evergreen.V67.Coord
import Evergreen.V67.Id
import Evergreen.V67.IdDict
import Evergreen.V67.Tile
import Evergreen.V67.Units


type alias Value =
    { userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.CellLocalUnit
    , value : Evergreen.V67.Tile.Tile
    , colors : Evergreen.V67.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V67.Coord.Coord Evergreen.V67.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V67.Coord.Coord Evergreen.V67.Units.CellLocalUnit)
        }
