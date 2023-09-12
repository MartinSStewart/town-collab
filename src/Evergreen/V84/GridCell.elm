module Evergreen.V84.GridCell exposing (..)

import AssocSet
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.Id
import Evergreen.V84.IdDict
import Evergreen.V84.Tile
import Evergreen.V84.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.CellLocalUnit
    , value : Evergreen.V84.Tile.Tile
    , colors : Evergreen.V84.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V84.Coord.Coord Evergreen.V84.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V84.Coord.Coord Evergreen.V84.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
