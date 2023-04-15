module Evergreen.V75.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.Id
import Evergreen.V75.Tile
import Evergreen.V75.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , path : Evergreen.V75.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
        , path : Evergreen.V75.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V75.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
        , homePath : Evergreen.V75.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , color : Evergreen.V75.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
                , path : Evergreen.V75.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V75.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
