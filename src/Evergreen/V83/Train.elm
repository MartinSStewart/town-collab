module Evergreen.V83.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V83.Color
import Evergreen.V83.Coord
import Evergreen.V83.Id
import Evergreen.V83.Tile
import Evergreen.V83.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , path : Evergreen.V83.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
        , path : Evergreen.V83.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V83.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
        , homePath : Evergreen.V83.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , color : Evergreen.V83.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
                , path : Evergreen.V83.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V83.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
