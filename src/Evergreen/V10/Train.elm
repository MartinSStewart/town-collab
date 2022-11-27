module Evergreen.V10.Train exposing (..)

import Duration
import Evergreen.V10.Coord
import Evergreen.V10.Id
import Evergreen.V10.Tile
import Evergreen.V10.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
    , path : Evergreen.V10.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
        , path : Evergreen.V10.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V10.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
        , homePath : Evergreen.V10.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        }
