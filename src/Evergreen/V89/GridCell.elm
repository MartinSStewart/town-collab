module Evergreen.V89.GridCell exposing (..)

import AssocSet
import Evergreen.V89.Color
import Evergreen.V89.Coord
import Evergreen.V89.Id
import Evergreen.V89.IdDict
import Evergreen.V89.Tile
import Evergreen.V89.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.CellLocalUnit
    , value : Evergreen.V89.Tile.Tile
    , colors : Evergreen.V89.Color.Colors
    }


type CellData
    = CellData
        { history : List Value
        , undoPoint : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V89.Coord.Coord Evergreen.V89.Units.CellLocalUnit)
        , cache : List Value
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V89.Coord.Coord Evergreen.V89.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }
