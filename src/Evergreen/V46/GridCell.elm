module Evergreen.V46.GridCell exposing (..)

import AssocSet
import Dict
import Evergreen.V46.Color
import Evergreen.V46.Coord
import Evergreen.V46.Id
import Evergreen.V46.Tile
import Evergreen.V46.Units


type alias Value =
    { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.CellLocalUnit
    , value : Evergreen.V46.Tile.Tile
    , colors : Evergreen.V46.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , railSplitToggled : AssocSet.Set (Evergreen.V46.Coord.Coord Evergreen.V46.Units.CellLocalUnit)
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict.Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V46.Coord.Coord Evergreen.V46.Units.CellLocalUnit)
        }
