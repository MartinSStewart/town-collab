module Evergreen.V126.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.Id
import Evergreen.V126.IdDict
import Evergreen.V126.Tile
import Evergreen.V126.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.CellLocalUnit
    , tile : Evergreen.V126.Tile.Tile
    , colors : Evergreen.V126.Color.Colors
    , time : Effect.Time.Posix
    }


type alias Cache =
    List Value


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V126.Coord.Coord Evergreen.V126.Units.CellLocalUnit)
        , cache : Cache
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Int
        , cache : Cache
        , railSplitToggled : AssocSet.Set (Evergreen.V126.Coord.Coord Evergreen.V126.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
