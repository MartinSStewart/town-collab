module Evergreen.V111.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.Id
import Evergreen.V111.IdDict
import Evergreen.V111.Tile
import Evergreen.V111.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.CellLocalUnit
    , tile : Evergreen.V111.Tile.Tile
    , colors : Evergreen.V111.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V111.Coord.Coord Evergreen.V111.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V111.Coord.Coord Evergreen.V111.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
