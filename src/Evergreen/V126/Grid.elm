module Evergreen.V126.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.GridCell
import Evergreen.V126.Id
import Evergreen.V126.Tile
import Evergreen.V126.Units


type alias LocalGridChange =
    { position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , change : Evergreen.V126.Tile.Tile
    , colors : Evergreen.V126.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , change : Evergreen.V126.Tile.Tile
    , userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , colors : Evergreen.V126.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V126.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V126.GridCell.CellData)
