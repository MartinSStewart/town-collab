module Evergreen.V112.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V112.Color
import Evergreen.V112.Coord
import Evergreen.V112.Id
import Evergreen.V112.Tile
import Evergreen.V112.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , path : Evergreen.V112.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
        , path : Evergreen.V112.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V112.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
        , homePath : Evergreen.V112.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , color : Evergreen.V112.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
                , path : Evergreen.V112.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V112.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
