module Evergreen.V108.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V108.Color
import Evergreen.V108.Coord
import Evergreen.V108.Id
import Evergreen.V108.IdDict
import Evergreen.V108.Tile
import Evergreen.V108.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.CellLocalUnit
    , tile : Evergreen.V108.Tile.Tile
    , colors : Evergreen.V108.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V108.Coord.Coord Evergreen.V108.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V108.Coord.Coord Evergreen.V108.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
