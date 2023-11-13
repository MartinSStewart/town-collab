module Evergreen.V113.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.Id
import Evergreen.V113.IdDict
import Evergreen.V113.Tile
import Evergreen.V113.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.CellLocalUnit
    , tile : Evergreen.V113.Tile.Tile
    , colors : Evergreen.V113.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V113.Coord.Coord Evergreen.V113.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V113.Coord.Coord Evergreen.V113.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
