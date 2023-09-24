module Evergreen.V88.GridCell exposing (..)

import AssocSet
import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.Id
import Evergreen.V88.IdDict
import Evergreen.V88.Tile
import Evergreen.V88.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.CellLocalUnit
    , value : Evergreen.V88.Tile.Tile
    , colors : Evergreen.V88.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V88.Coord.Coord Evergreen.V88.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V88.Coord.Coord Evergreen.V88.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
