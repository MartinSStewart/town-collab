module Evergreen.V110.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V110.Color
import Evergreen.V110.Coord
import Evergreen.V110.Id
import Evergreen.V110.IdDict
import Evergreen.V110.Tile
import Evergreen.V110.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.CellLocalUnit
    , tile : Evergreen.V110.Tile.Tile
    , colors : Evergreen.V110.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V110.Coord.Coord Evergreen.V110.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V110.Coord.Coord Evergreen.V110.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
