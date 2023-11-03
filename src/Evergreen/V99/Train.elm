module Evergreen.V99.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V99.Color
import Evergreen.V99.Coord
import Evergreen.V99.Id
import Evergreen.V99.Tile
import Evergreen.V99.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , path : Evergreen.V99.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
        , path : Evergreen.V99.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V99.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
        , homePath : Evergreen.V99.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , color : Evergreen.V99.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
                , path : Evergreen.V99.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V99.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
