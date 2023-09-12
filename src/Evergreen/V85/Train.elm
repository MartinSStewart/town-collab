module Evergreen.V85.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.Id
import Evergreen.V85.Tile
import Evergreen.V85.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , path : Evergreen.V85.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
        , path : Evergreen.V85.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V85.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
        , homePath : Evergreen.V85.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , color : Evergreen.V85.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
                , path : Evergreen.V85.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V85.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
