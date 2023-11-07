module Evergreen.V107.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V107.Color
import Evergreen.V107.Coord
import Evergreen.V107.Id
import Evergreen.V107.Tile
import Evergreen.V107.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , path : Evergreen.V107.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
        , path : Evergreen.V107.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V107.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
        , homePath : Evergreen.V107.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , color : Evergreen.V107.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
                , path : Evergreen.V107.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V107.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
