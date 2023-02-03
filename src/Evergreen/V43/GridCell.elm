module Evergreen.V43.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V43.Color
import Evergreen.V43.Coord
import Evergreen.V43.Id
import Evergreen.V43.Tile
import Evergreen.V43.Units


type alias Value =
    { userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    , position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.CellLocalUnit
    , value : Evergreen.V43.Tile.Tile
    , colors : Evergreen.V43.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V43.Coord.Coord Evergreen.V43.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V43.Coord.Coord Evergreen.V43.Units.CellLocalUnit)
        }
