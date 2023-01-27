module Evergreen.V47.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V47.Color
import Evergreen.V47.Coord
import Evergreen.V47.Id
import Evergreen.V47.Tile
import Evergreen.V47.Units


type alias Value =
    { userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.CellLocalUnit
    , value : Evergreen.V47.Tile.Tile
    , colors : Evergreen.V47.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V47.Coord.Coord Evergreen.V47.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V47.Coord.Coord Evergreen.V47.Units.CellLocalUnit)
        }
