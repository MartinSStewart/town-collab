module Evergreen.V113.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.Id
import Evergreen.V113.Tile
import Evergreen.V113.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , path : Evergreen.V113.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
        , path : Evergreen.V113.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V113.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
        , homePath : Evergreen.V113.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        , color : Evergreen.V113.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
                , path : Evergreen.V113.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V113.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
