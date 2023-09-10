module Evergreen.V82.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V82.Color
import Evergreen.V82.Coord
import Evergreen.V82.Id
import Evergreen.V82.Tile
import Evergreen.V82.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , path : Evergreen.V82.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
        , path : Evergreen.V82.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V82.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
        , homePath : Evergreen.V82.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , color : Evergreen.V82.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
                , path : Evergreen.V82.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V82.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
