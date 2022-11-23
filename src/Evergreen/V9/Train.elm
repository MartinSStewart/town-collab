module Evergreen.V9.Train exposing (..)

import Duration
import Evergreen.V9.Coord
import Evergreen.V9.Id
import Evergreen.V9.Tile
import Evergreen.V9.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , path : Evergreen.V9.Tile.RailPath
    , reversed : Bool
    }


type alias Train =
    { position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , path : Evergreen.V9.Tile.RailPath
    , previousPaths : List PreviousPath
    , t : Float
    , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V9.Units.TileLocalUnit Duration.Seconds)
    , stoppedAtPostOffice :
        Maybe
            { time : Time.Posix
            , userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            }
    , home : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , isStuck : Maybe Time.Posix
    }
