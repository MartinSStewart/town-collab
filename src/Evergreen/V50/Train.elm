module Evergreen.V50.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V50.Coord
import Evergreen.V50.Id
import Evergreen.V50.Tile
import Evergreen.V50.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
    , path : Evergreen.V50.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
        , path : Evergreen.V50.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V50.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
        , homePath : Evergreen.V50.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
                , path : Evergreen.V50.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V50.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
