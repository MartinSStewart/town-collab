module Evergreen.V62.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V62.Color
import Evergreen.V62.Coord
import Evergreen.V62.Id
import Evergreen.V62.Tile
import Evergreen.V62.Units


type alias Value =
    { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.CellLocalUnit
    , value : Evergreen.V62.Tile.Tile
    , colors : Evergreen.V62.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V62.Coord.Coord Evergreen.V62.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V62.Coord.Coord Evergreen.V62.Units.CellLocalUnit)
        }
