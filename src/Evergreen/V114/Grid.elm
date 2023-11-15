module Evergreen.V114.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V114.Color
import Evergreen.V114.Coord
import Evergreen.V114.GridCell
import Evergreen.V114.Id
import Evergreen.V114.Tile
import Evergreen.V114.Units


type alias LocalGridChange =
    { position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , change : Evergreen.V114.Tile.Tile
    , colors : Evergreen.V114.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , change : Evergreen.V114.Tile.Tile
    , userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , colors : Evergreen.V114.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V114.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V114.GridCell.CellData)
