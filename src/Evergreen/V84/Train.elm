module Evergreen.V84.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.Id
import Evergreen.V84.Tile
import Evergreen.V84.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , path : Evergreen.V84.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
        , path : Evergreen.V84.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V84.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
        , homePath : Evergreen.V84.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , color : Evergreen.V84.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
                , path : Evergreen.V84.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V84.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
