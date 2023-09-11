module Evergreen.V83.GridCell exposing (..)

import AssocSet
import Evergreen.V83.Color
import Evergreen.V83.Coord
import Evergreen.V83.Id
import Evergreen.V83.IdDict
import Evergreen.V83.Tile
import Evergreen.V83.Units


type alias Value =
    { userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.CellLocalUnit
    , value : Evergreen.V83.Tile.Tile
    , colors : Evergreen.V83.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V83.Coord.Coord Evergreen.V83.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V83.Coord.Coord Evergreen.V83.Units.CellLocalUnit)
        , mapCache : Int
        }
