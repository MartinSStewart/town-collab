module Evergreen.V33.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V33.Color
import Evergreen.V33.Coord
import Evergreen.V33.Id
import Evergreen.V33.Tile
import Evergreen.V33.Units


type alias Value =
    { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.CellLocalUnit
    , value : Evergreen.V33.Tile.Tile
    , colors : Evergreen.V33.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V33.Coord.Coord Evergreen.V33.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V33.Coord.Coord Evergreen.V33.Units.CellLocalUnit)
        }
