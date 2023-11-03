module Evergreen.V100.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V100.Color
import Evergreen.V100.Coord
import Evergreen.V100.Id
import Evergreen.V100.Tile
import Evergreen.V100.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , path : Evergreen.V100.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
        , path : Evergreen.V100.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V100.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
        , homePath : Evergreen.V100.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , color : Evergreen.V100.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
                , path : Evergreen.V100.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V100.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
