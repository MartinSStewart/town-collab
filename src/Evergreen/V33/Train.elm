module Evergreen.V33.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V33.Coord
import Evergreen.V33.Id
import Evergreen.V33.Tile
import Evergreen.V33.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
    , path : Evergreen.V33.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
        , path : Evergreen.V33.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V33.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
        , homePath : Evergreen.V33.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
                , path : Evergreen.V33.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V33.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
