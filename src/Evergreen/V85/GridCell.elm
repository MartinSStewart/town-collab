module Evergreen.V85.GridCell exposing (..)

import AssocSet
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.Id
import Evergreen.V85.IdDict
import Evergreen.V85.Tile
import Evergreen.V85.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.CellLocalUnit
    , value : Evergreen.V85.Tile.Tile
    , colors : Evergreen.V85.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V85.Coord.Coord Evergreen.V85.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V85.Coord.Coord Evergreen.V85.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
