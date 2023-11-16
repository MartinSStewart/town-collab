module Evergreen.V115.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.Id
import Evergreen.V115.Tile
import Evergreen.V115.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , path : Evergreen.V115.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
        , path : Evergreen.V115.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V115.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
        , homePath : Evergreen.V115.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , color : Evergreen.V115.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
                , path : Evergreen.V115.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V115.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
