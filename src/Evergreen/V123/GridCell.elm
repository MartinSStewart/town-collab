module Evergreen.V123.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V123.Color
import Evergreen.V123.Coord
import Evergreen.V123.Id
import Evergreen.V123.IdDict
import Evergreen.V123.Tile
import Evergreen.V123.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.CellLocalUnit
    , tile : Evergreen.V123.Tile.Tile
    , colors : Evergreen.V123.Color.Colors
    , time : Effect.Time.Posix
    }


type alias Cache =
    List Value


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V123.Coord.Coord Evergreen.V123.Units.CellLocalUnit)
        , cache : Cache
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Int
        , cache : Cache
        , railSplitToggled : AssocSet.Set (Evergreen.V123.Coord.Coord Evergreen.V123.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
