module Evergreen.V42.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V42.Color
import Evergreen.V42.Coord
import Evergreen.V42.Id
import Evergreen.V42.Tile
import Evergreen.V42.Units


type alias Value =
    { userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.CellLocalUnit
    , value : Evergreen.V42.Tile.Tile
    , colors : Evergreen.V42.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V42.Coord.Coord Evergreen.V42.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V42.Coord.Coord Evergreen.V42.Units.CellLocalUnit)
        }
