module Evergreen.V109.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.GridCell
import Evergreen.V109.Id
import Evergreen.V109.Tile
import Evergreen.V109.Units


type alias LocalGridChange =
    { position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , change : Evergreen.V109.Tile.Tile
    , colors : Evergreen.V109.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , change : Evergreen.V109.Tile.Tile
    , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , colors : Evergreen.V109.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V109.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V109.GridCell.CellData)
