module Evergreen.V72.GridCell exposing (..)

import AssocSet
import Evergreen.V72.Color
import Evergreen.V72.Coord
import Evergreen.V72.Id
import Evergreen.V72.IdDict
import Evergreen.V72.Tile
import Evergreen.V72.Units


type alias Value =
    { userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.CellLocalUnit
    , value : Evergreen.V72.Tile.Tile
    , colors : Evergreen.V72.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V72.Coord.Coord Evergreen.V72.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V72.Coord.Coord Evergreen.V72.Units.CellLocalUnit)
        }
