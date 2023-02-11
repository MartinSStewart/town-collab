module Evergreen.V59.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V59.Color
import Evergreen.V59.Coord
import Evergreen.V59.Id
import Evergreen.V59.Tile
import Evergreen.V59.Units


type alias Value =
    { userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.CellLocalUnit
    , value : Evergreen.V59.Tile.Tile
    , colors : Evergreen.V59.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V59.Coord.Coord Evergreen.V59.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V59.Coord.Coord Evergreen.V59.Units.CellLocalUnit)
        }
