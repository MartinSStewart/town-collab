module Evergreen.V57.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V57.Coord
import Evergreen.V57.Id
import Evergreen.V57.Tile
import Evergreen.V57.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
    , path : Evergreen.V57.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
        , path : Evergreen.V57.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V57.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
        , homePath : Evergreen.V57.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
                , path : Evergreen.V57.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V57.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
