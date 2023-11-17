module Evergreen.V116.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V116.Color
import Evergreen.V116.Coord
import Evergreen.V116.Id
import Evergreen.V116.IdDict
import Evergreen.V116.Tile
import Evergreen.V116.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.CellLocalUnit
    , tile : Evergreen.V116.Tile.Tile
    , colors : Evergreen.V116.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V116.Coord.Coord Evergreen.V116.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V116.Coord.Coord Evergreen.V116.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
