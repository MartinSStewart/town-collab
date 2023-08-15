module Evergreen.V77.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.Id
import Evergreen.V77.Tile
import Evergreen.V77.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , path : Evergreen.V77.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
        , path : Evergreen.V77.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V77.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
        , homePath : Evergreen.V77.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , color : Evergreen.V77.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
                , path : Evergreen.V77.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V77.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
