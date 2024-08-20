module Evergreen.V134.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.Id
import Evergreen.V134.Tile
import Evergreen.V134.Units
import Math.Vector2
import SeqDict


type alias Value =
    { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.CellLocalUnit
    , tile : Evergreen.V134.Tile.Tile
    , colors : Evergreen.V134.Color.Colors
    , time : Effect.Time.Posix
    }


type alias Cache =
    List Value


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Int
        , railSplitToggled : AssocSet.Set (Evergreen.V134.Coord.Coord Evergreen.V134.Units.CellLocalUnit)
        , cache : Cache
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Int
        , cache : Cache
        , railSplitToggled : AssocSet.Set (Evergreen.V134.Coord.Coord Evergreen.V134.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
