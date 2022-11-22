module Evergreen.V6.Train exposing (..)

import Duration
import Evergreen.V6.Coord
import Evergreen.V6.Id
import Evergreen.V6.Tile
import Evergreen.V6.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    , path : Evergreen.V6.Tile.RailPath
    , reversed : Bool
    }


type alias Train =
    { position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    , path : Evergreen.V6.Tile.RailPath
    , previousPaths : List PreviousPath
    , t : Float
    , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V6.Units.TileLocalUnit Duration.Seconds)
    , stoppedAtPostOffice :
        Maybe
            { time : Time.Posix
            , userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
            }
    , home : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    }
