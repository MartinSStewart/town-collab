module Evergreen.V72.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V72.Color
import Evergreen.V72.Coord
import Evergreen.V72.Id
import Evergreen.V72.Tile
import Evergreen.V72.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , path : Evergreen.V72.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
        , path : Evergreen.V72.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V72.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
        , homePath : Evergreen.V72.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , color : Evergreen.V72.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
                , path : Evergreen.V72.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V72.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
