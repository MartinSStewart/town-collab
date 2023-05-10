module Evergreen.V76.GridCell exposing (..)

import AssocSet
import Evergreen.V76.Color
import Evergreen.V76.Coord
import Evergreen.V76.Id
import Evergreen.V76.IdDict
import Evergreen.V76.Tile
import Evergreen.V76.Units


type alias Value =
    { userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.CellLocalUnit
    , value : Evergreen.V76.Tile.Tile
    , colors : Evergreen.V76.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V76.Coord.Coord Evergreen.V76.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V76.Coord.Coord Evergreen.V76.Units.CellLocalUnit)
        }
