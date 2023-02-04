module Evergreen.V56.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V56.Color
import Evergreen.V56.Coord
import Evergreen.V56.Id
import Evergreen.V56.Tile
import Evergreen.V56.Units


type alias Value =
    { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.CellLocalUnit
    , value : Evergreen.V56.Tile.Tile
    , colors : Evergreen.V56.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V56.Coord.Coord Evergreen.V56.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V56.Coord.Coord Evergreen.V56.Units.CellLocalUnit)
        }
