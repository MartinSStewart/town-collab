module Evergreen.V115.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.Id
import Evergreen.V115.IdDict
import Evergreen.V115.Tile
import Evergreen.V115.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.CellLocalUnit
    , tile : Evergreen.V115.Tile.Tile
    , colors : Evergreen.V115.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V115.Coord.Coord Evergreen.V115.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V115.Coord.Coord Evergreen.V115.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
