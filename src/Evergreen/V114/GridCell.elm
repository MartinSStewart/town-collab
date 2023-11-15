module Evergreen.V114.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V114.Color
import Evergreen.V114.Coord
import Evergreen.V114.Id
import Evergreen.V114.IdDict
import Evergreen.V114.Tile
import Evergreen.V114.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.CellLocalUnit
    , tile : Evergreen.V114.Tile.Tile
    , colors : Evergreen.V114.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V114.Coord.Coord Evergreen.V114.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V114.Coord.Coord Evergreen.V114.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
