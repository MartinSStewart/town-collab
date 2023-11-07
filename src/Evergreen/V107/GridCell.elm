module Evergreen.V107.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V107.Color
import Evergreen.V107.Coord
import Evergreen.V107.Id
import Evergreen.V107.IdDict
import Evergreen.V107.Tile
import Evergreen.V107.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.CellLocalUnit
    , tile : Evergreen.V107.Tile.Tile
    , colors : Evergreen.V107.Color.Colors
    , time : Effect.Time.Posix
    }


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V107.Coord.Coord Evergreen.V107.Units.CellLocalUnit)
        , cache : List Value
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Evergreen.V107.Coord.Coord Evergreen.V107.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
