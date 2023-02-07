module Evergreen.V57.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V57.Color
import Evergreen.V57.Coord
import Evergreen.V57.Id
import Evergreen.V57.Tile
import Evergreen.V57.Units


type alias Value =
    { userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.CellLocalUnit
    , value : Evergreen.V57.Tile.Tile
    , colors : Evergreen.V57.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V57.Coord.Coord Evergreen.V57.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V57.Coord.Coord Evergreen.V57.Units.CellLocalUnit)
        }
