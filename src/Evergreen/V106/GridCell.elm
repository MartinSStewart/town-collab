module Evergreen.V106.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V106.Color
import Evergreen.V106.Coord
import Evergreen.V106.Id
import Evergreen.V106.IdDict
import Evergreen.V106.Tile
import Evergreen.V106.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
    , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.CellLocalUnit
    , tile : Evergreen.V106.Tile.Tile
    , colors : Evergreen.V106.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V106.Coord.Coord Evergreen.V106.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V106.Coord.Coord Evergreen.V106.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
