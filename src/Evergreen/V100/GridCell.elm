module Evergreen.V100.GridCell exposing (..)

import AssocSet
import Effect.Time
import Evergreen.V100.Color
import Evergreen.V100.Coord
import Evergreen.V100.Id
import Evergreen.V100.IdDict
import Evergreen.V100.Tile
import Evergreen.V100.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.CellLocalUnit
    , value : Evergreen.V100.Tile.Tile
    , colors : Evergreen.V100.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V100.Coord.Coord Evergreen.V100.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V100.Coord.Coord Evergreen.V100.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
