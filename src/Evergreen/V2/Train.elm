module Evergreen.V2.Train exposing (..)

import Duration
import Evergreen.V2.Coord
import Evergreen.V2.Id
import Evergreen.V2.Tile
import Evergreen.V2.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
    , path : Evergreen.V2.Tile.RailPath
    , reversed : Bool
    }


type alias Train =
    { position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
    , path : Evergreen.V2.Tile.RailPath
    , previousPaths : List PreviousPath
    , t : Float
    , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V2.Units.TileLocalUnit Duration.Seconds)
    , stoppedAtPostOffice :
        Maybe
            { time : Time.Posix
            , userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
            }
    }
