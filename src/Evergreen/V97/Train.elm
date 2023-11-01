module Evergreen.V97.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V97.Color
import Evergreen.V97.Coord
import Evergreen.V97.Id
import Evergreen.V97.Tile
import Evergreen.V97.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , path : Evergreen.V97.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
        , path : Evergreen.V97.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V97.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
        , homePath : Evergreen.V97.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , color : Evergreen.V97.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
                , path : Evergreen.V97.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V97.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
