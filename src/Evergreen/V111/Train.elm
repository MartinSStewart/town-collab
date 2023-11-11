module Evergreen.V111.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.Id
import Evergreen.V111.Tile
import Evergreen.V111.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , path : Evergreen.V111.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
        , path : Evergreen.V111.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V111.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
        , homePath : Evergreen.V111.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        , color : Evergreen.V111.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
                , path : Evergreen.V111.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V111.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
