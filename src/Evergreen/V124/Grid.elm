module Evergreen.V124.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V124.Color
import Evergreen.V124.Coord
import Evergreen.V124.GridCell
import Evergreen.V124.Id
import Evergreen.V124.Tile
import Evergreen.V124.Units


type alias LocalGridChange =
    { position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , change : Evergreen.V124.Tile.Tile
    , colors : Evergreen.V124.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , change : Evergreen.V124.Tile.Tile
    , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , colors : Evergreen.V124.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V124.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V124.GridCell.CellData)
