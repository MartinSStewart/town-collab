module Evergreen.V67.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V67.Coord
import Evergreen.V67.Id
import Evergreen.V67.Tile
import Evergreen.V67.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
    , path : Evergreen.V67.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
        , path : Evergreen.V67.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V67.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
        , homePath : Evergreen.V67.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
                , path : Evergreen.V67.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V67.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
