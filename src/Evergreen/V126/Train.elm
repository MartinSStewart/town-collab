module Evergreen.V126.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.Id
import Evergreen.V126.Tile
import Evergreen.V126.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , path : Evergreen.V126.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
        { startedAt : Effect.Time.Posix
        }
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
        , path : Evergreen.V126.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V126.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
        , homePath : Evergreen.V126.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        , color : Evergreen.V126.Color.Color
        }


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
        , path : Evergreen.V126.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V126.Units.TileLocalUnit Duration.Seconds)
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        }
