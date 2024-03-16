module Evergreen.V125.GridCell exposing (..)

import AssocSet
import Bytes
import Effect.Time
import Evergreen.V125.Color
import Evergreen.V125.Coord
import Evergreen.V125.Id
import Evergreen.V125.IdDict
import Evergreen.V125.Tile
import Evergreen.V125.Units
import Math.Vector2


type alias Value =
    { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.CellLocalUnit
    , tile : Evergreen.V125.Tile.Tile
    , colors : Evergreen.V125.Color.Colors
    , time : Effect.Time.Posix
    }


type alias Cache =
    List Value


type CellData
    = CellData
        { history : Bytes.Bytes
        , undoPoint : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Int
        , railSplitToggled : AssocSet.Set (Evergreen.V125.Coord.Coord Evergreen.V125.Units.CellLocalUnit)
        , cache : Cache
        }


type FrontendHistory
    = FrontendEncoded Bytes.Bytes
    | FrontendDecoded (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Int
        , cache : Cache
        , railSplitToggled : AssocSet.Set (Evergreen.V125.Coord.Coord Evergreen.V125.Units.CellLocalUnit)
        , mapCache : Math.Vector2.Vec2
        }


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes.Bytes (List Value)
