module Evergreen.V50.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V50.Color
import Evergreen.V50.Coord
import Evergreen.V50.Id
import Evergreen.V50.Tile
import Evergreen.V50.Units


type alias Value =
    { userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.CellLocalUnit
    , value : Evergreen.V50.Tile.Tile
    , colors : Evergreen.V50.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V50.Coord.Coord Evergreen.V50.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V50.Coord.Coord Evergreen.V50.Units.CellLocalUnit)
        }
