module Evergreen.V106.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V106.Color
import Evergreen.V106.Coord
import Evergreen.V106.Id
import Evergreen.V106.Tile
import Evergreen.V106.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , path : Evergreen.V106.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
        , path : Evergreen.V106.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V106.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
        , homePath : Evergreen.V106.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , color : Evergreen.V106.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
                , path : Evergreen.V106.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V106.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
