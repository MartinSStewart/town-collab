module Evergreen.V97.GridCell exposing (..)

import AssocSet
import Effect.Time
import Evergreen.V97.Color
import Evergreen.V97.Coord
import Evergreen.V97.Id
import Evergreen.V97.IdDict
import Evergreen.V97.Tile
import Evergreen.V97.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.CellLocalUnit
    , value : Evergreen.V97.Tile.Tile
    , colors : Evergreen.V97.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V97.Coord.Coord Evergreen.V97.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V97.Coord.Coord Evergreen.V97.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
