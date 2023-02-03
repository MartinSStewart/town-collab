module Evergreen.V52.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V52.Color
import Evergreen.V52.Coord
import Evergreen.V52.Id
import Evergreen.V52.Tile
import Evergreen.V52.Units


type alias Value =
    { userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.CellLocalUnit
    , value : Evergreen.V52.Tile.Tile
    , colors : Evergreen.V52.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V52.Coord.Coord Evergreen.V52.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V52.Coord.Coord Evergreen.V52.Units.CellLocalUnit)
        }
