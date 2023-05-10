module Evergreen.V76.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V76.Color
import Evergreen.V76.Coord
import Evergreen.V76.Id
import Evergreen.V76.Tile
import Evergreen.V76.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , path : Evergreen.V76.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
        , path : Evergreen.V76.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V76.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
        , homePath : Evergreen.V76.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , color : Evergreen.V76.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
                , path : Evergreen.V76.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V76.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
