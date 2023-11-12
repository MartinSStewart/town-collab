module Evergreen.V112.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V112.Color
import Evergreen.V112.Coord
import Evergreen.V112.Id
import Evergreen.V112.IdDict
import Evergreen.V112.Tile
import Evergreen.V112.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.CellLocalUnit
    , tile : Evergreen.V112.Tile.Tile
    , colors : Evergreen.V112.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V112.Coord.Coord Evergreen.V112.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V112.Coord.Coord Evergreen.V112.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
