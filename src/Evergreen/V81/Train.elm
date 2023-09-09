module Evergreen.V81.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.Id
import Evergreen.V81.Tile
import Evergreen.V81.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , path : Evergreen.V81.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
        , path : Evergreen.V81.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V81.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
        , homePath : Evergreen.V81.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , color : Evergreen.V81.Color.Color
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
                , path : Evergreen.V81.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V81.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
