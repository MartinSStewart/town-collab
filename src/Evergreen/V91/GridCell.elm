module Evergreen.V91.GridCell exposing (..)

import AssocSet
import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.Id
import Evergreen.V91.IdDict
import Evergreen.V91.Tile
import Evergreen.V91.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.CellLocalUnit
    , value : Evergreen.V91.Tile.Tile
    , colors : Evergreen.V91.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V91.Coord.Coord Evergreen.V91.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V91.Coord.Coord Evergreen.V91.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
