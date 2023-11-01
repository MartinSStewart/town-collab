module Evergreen.V95.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V95.Color
import Evergreen.V95.Coord
import Evergreen.V95.Id
import Evergreen.V95.Tile
import Evergreen.V95.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , path : Evergreen.V95.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
        , path : Evergreen.V95.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V95.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
        , homePath : Evergreen.V95.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , color : Evergreen.V95.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
                , path : Evergreen.V95.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V95.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
