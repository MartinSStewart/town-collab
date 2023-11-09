module Evergreen.V109.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.Id
import Evergreen.V109.Tile
import Evergreen.V109.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , path : Evergreen.V109.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
        , path : Evergreen.V109.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V109.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
        , homePath : Evergreen.V109.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , color : Evergreen.V109.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
                , path : Evergreen.V109.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V109.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
