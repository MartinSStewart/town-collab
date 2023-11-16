module Evergreen.V115.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.GridCell
import Evergreen.V115.Id
import Evergreen.V115.Tile
import Evergreen.V115.Units


type alias LocalGridChange =
    { position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , change : Evergreen.V115.Tile.Tile
    , colors : Evergreen.V115.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , change : Evergreen.V115.Tile.Tile
    , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , colors : Evergreen.V115.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V115.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V115.GridCell.CellData)
