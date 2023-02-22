module Evergreen.V69.GridCell exposing (..)

import AssocSet
import Evergreen.V69.Color
import Evergreen.V69.Coord
import Evergreen.V69.Id
import Evergreen.V69.IdDict
import Evergreen.V69.Tile
import Evergreen.V69.Units


type alias Value =
    { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.CellLocalUnit
    , value : Evergreen.V69.Tile.Tile
    , colors : Evergreen.V69.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V69.Coord.Coord Evergreen.V69.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V69.Coord.Coord Evergreen.V69.Units.CellLocalUnit)
        }
