module Evergreen.V91.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.Id
import Evergreen.V91.Tile
import Evergreen.V91.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , path : Evergreen.V91.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
        , path : Evergreen.V91.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V91.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
        , homePath : Evergreen.V91.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , color : Evergreen.V91.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
                , path : Evergreen.V91.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V91.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
