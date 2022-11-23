module Evergreen.V8.Train exposing (..)

import Duration
import Evergreen.V8.Coord
import Evergreen.V8.Id
import Evergreen.V8.Tile
import Evergreen.V8.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    , path : Evergreen.V8.Tile.RailPath
    , reversed : Bool
    }


type alias Train =
    { position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    , path : Evergreen.V8.Tile.RailPath
    , previousPaths : List PreviousPath
    , t : Float
    , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V8.Units.TileLocalUnit Duration.Seconds)
    , stoppedAtPostOffice :
        Maybe
            { time : Time.Posix
            , userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
            }
    , home : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    }
