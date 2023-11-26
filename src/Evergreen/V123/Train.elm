module Evergreen.V123.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V123.Color
import Evergreen.V123.Coord
import Evergreen.V123.Id
import Evergreen.V123.Tile
import Evergreen.V123.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , path : Evergreen.V123.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
        , path : Evergreen.V123.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V123.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
        , homePath : Evergreen.V123.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        , color : Evergreen.V123.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
                , path : Evergreen.V123.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V123.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
