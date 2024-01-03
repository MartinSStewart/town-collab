module Evergreen.V124.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V124.Color
import Evergreen.V124.Coord
import Evergreen.V124.Id
import Evergreen.V124.IdDict
import Evergreen.V124.Tile
import Evergreen.V124.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.CellLocalUnit
    , tile : Evergreen.V124.Tile.Tile
    , colors : Evergreen.V124.Color.Colors
    , time : Effect.Time.Posix
    }


type alias Cache =
    List Value


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V124.Coord.Coord Evergreen.V124.Units.CellLocalUnit)
        , cache : Cache
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Int
        , cache : Cache
        , railSplitToggled : AssocSet.Set (Evergreen.V124.Coord.Coord Evergreen.V124.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
