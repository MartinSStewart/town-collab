module Evergreen.V74.GridCell exposing (..)

import AssocSet
import Evergreen.V74.Color
import Evergreen.V74.Coord
import Evergreen.V74.Id
import Evergreen.V74.IdDict
import Evergreen.V74.Tile
import Evergreen.V74.Units


type alias Value =
    { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.CellLocalUnit
    , value : Evergreen.V74.Tile.Tile
    , colors : Evergreen.V74.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V74.Coord.Coord Evergreen.V74.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V74.Coord.Coord Evergreen.V74.Units.CellLocalUnit)
        }
