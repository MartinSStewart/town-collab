module Evergreen.V107.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V107.Color
import Evergreen.V107.Coord
import Evergreen.V107.GridCell
import Evergreen.V107.Id
import Evergreen.V107.Tile
import Evergreen.V107.Units


type alias LocalGridChange =
    { position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , change : Evergreen.V107.Tile.Tile
    , colors : Evergreen.V107.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , change : Evergreen.V107.Tile.Tile
    , userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , colors : Evergreen.V107.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V107.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V107.GridCell.CellData)
