module Evergreen.V58.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V58.Color
import Evergreen.V58.Coord
import Evergreen.V58.Id
import Evergreen.V58.Tile
import Evergreen.V58.Units


type alias Value =
    { userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.CellLocalUnit
    , value : Evergreen.V58.Tile.Tile
    , colors : Evergreen.V58.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V58.Coord.Coord Evergreen.V58.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V58.Coord.Coord Evergreen.V58.Units.CellLocalUnit)
        }
