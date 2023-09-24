module Evergreen.V88.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.Id
import Evergreen.V88.Tile
import Evergreen.V88.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , path : Evergreen.V88.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
        , path : Evergreen.V88.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V88.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
        , homePath : Evergreen.V88.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , color : Evergreen.V88.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
                , path : Evergreen.V88.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V88.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
