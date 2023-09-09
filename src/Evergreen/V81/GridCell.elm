module Evergreen.V81.GridCell exposing (..)

import AssocSet
import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.Id
import Evergreen.V81.IdDict
import Evergreen.V81.Tile
import Evergreen.V81.Units


type alias Value =
    { userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.CellLocalUnit
    , value : Evergreen.V81.Tile.Tile
    , colors : Evergreen.V81.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V81.Coord.Coord Evergreen.V81.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V81.Coord.Coord Evergreen.V81.Units.CellLocalUnit)
        }
