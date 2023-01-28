module Evergreen.V49.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V49.Color
import Evergreen.V49.Coord
import Evergreen.V49.Id
import Evergreen.V49.Tile
import Evergreen.V49.Units


type alias Value =
    { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.CellLocalUnit
    , value : Evergreen.V49.Tile.Tile
    , colors : Evergreen.V49.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V49.Coord.Coord Evergreen.V49.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V49.Coord.Coord Evergreen.V49.Units.CellLocalUnit)
        }
