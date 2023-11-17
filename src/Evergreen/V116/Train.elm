module Evergreen.V116.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V116.Color
import Evergreen.V116.Coord
import Evergreen.V116.Id
import Evergreen.V116.Tile
import Evergreen.V116.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , path : Evergreen.V116.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
        , path : Evergreen.V116.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V116.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
        , homePath : Evergreen.V116.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , color : Evergreen.V116.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
                , path : Evergreen.V116.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V116.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
