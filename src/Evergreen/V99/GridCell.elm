module Evergreen.V99.GridCell exposing (..)

import AssocSet
import Effect.Time
import Evergreen.V99.Color
import Evergreen.V99.Coord
import Evergreen.V99.Id
import Evergreen.V99.IdDict
import Evergreen.V99.Tile
import Evergreen.V99.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.CellLocalUnit
    , value : Evergreen.V99.Tile.Tile
    , colors : Evergreen.V99.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V99.Coord.Coord Evergreen.V99.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V99.Coord.Coord Evergreen.V99.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
