module Evergreen.V134.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.Id
import Evergreen.V134.Tile
import Evergreen.V134.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , path : Evergreen.V134.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
        { startedAt : Effect.Time.Posix
        }
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
        , path : Evergreen.V134.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V134.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
        , homePath : Evergreen.V134.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , color : Evergreen.V134.Color.Color
        }


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
        , path : Evergreen.V134.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V134.Units.TileLocalUnit Duration.Seconds)
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        }
