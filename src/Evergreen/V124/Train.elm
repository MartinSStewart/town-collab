module Evergreen.V124.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V124.Color
import Evergreen.V124.Coord
import Evergreen.V124.Id
import Evergreen.V124.Tile
import Evergreen.V124.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , path : Evergreen.V124.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
        , path : Evergreen.V124.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V124.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
        , homePath : Evergreen.V124.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , color : Evergreen.V124.Color.Color
        }


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
        , path : Evergreen.V124.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V124.Units.TileLocalUnit Duration.Seconds)
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        }
