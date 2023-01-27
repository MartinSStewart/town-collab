module Evergreen.V48.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V48.Color
import Evergreen.V48.Coord
import Evergreen.V48.Id
import Evergreen.V48.Tile
import Evergreen.V48.Units


type alias Value =
    { userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.CellLocalUnit
    , value : Evergreen.V48.Tile.Tile
    , colors : Evergreen.V48.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V48.Coord.Coord Evergreen.V48.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V48.Coord.Coord Evergreen.V48.Units.CellLocalUnit)
        }
