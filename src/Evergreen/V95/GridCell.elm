module Evergreen.V95.GridCell exposing (..)

import AssocSet
import Effect.Time
import Evergreen.V95.Color
import Evergreen.V95.Coord
import Evergreen.V95.Id
import Evergreen.V95.IdDict
import Evergreen.V95.Tile
import Evergreen.V95.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.CellLocalUnit
    , value : Evergreen.V95.Tile.Tile
    , colors : Evergreen.V95.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V95.Coord.Coord Evergreen.V95.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V95.Coord.Coord Evergreen.V95.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
