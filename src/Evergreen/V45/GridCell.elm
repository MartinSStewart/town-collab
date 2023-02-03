module Evergreen.V45.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V45.Color
import Evergreen.V45.Coord
import Evergreen.V45.Id
import Evergreen.V45.Tile
import Evergreen.V45.Units


type alias Value =
    { userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.CellLocalUnit
    , value : Evergreen.V45.Tile.Tile
    , colors : Evergreen.V45.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V45.Coord.Coord Evergreen.V45.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V45.Coord.Coord Evergreen.V45.Units.CellLocalUnit)
        }
