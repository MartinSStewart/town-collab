module Evergreen.V93.GridCell exposing (..)

import AssocSet
import Effect.Time
import Evergreen.V93.Color
import Evergreen.V93.Coord
import Evergreen.V93.Id
import Evergreen.V93.IdDict
import Evergreen.V93.Tile
import Evergreen.V93.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.CellLocalUnit
    , value : Evergreen.V93.Tile.Tile
    , colors : Evergreen.V93.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V93.Coord.Coord Evergreen.V93.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V93.Coord.Coord Evergreen.V93.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
