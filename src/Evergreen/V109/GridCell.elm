module Evergreen.V109.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.Id
import Evergreen.V109.IdDict
import Evergreen.V109.Tile
import Evergreen.V109.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.CellLocalUnit
    , tile : Evergreen.V109.Tile.Tile
    , colors : Evergreen.V109.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V109.Coord.Coord Evergreen.V109.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V109.Coord.Coord Evergreen.V109.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
