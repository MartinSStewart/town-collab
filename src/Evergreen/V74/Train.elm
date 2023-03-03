module Evergreen.V74.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V74.Color
import Evergreen.V74.Coord
import Evergreen.V74.Id
import Evergreen.V74.Tile
import Evergreen.V74.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , path : Evergreen.V74.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
        , path : Evergreen.V74.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V74.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
        , homePath : Evergreen.V74.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , color : Evergreen.V74.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
                , path : Evergreen.V74.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V74.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
