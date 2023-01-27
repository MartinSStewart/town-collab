module Evergreen.V48.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V48.Coord
import Evergreen.V48.Id
import Evergreen.V48.Tile
import Evergreen.V48.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
    , path : Evergreen.V48.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
        , path : Evergreen.V48.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V48.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
        , homePath : Evergreen.V48.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
                , path : Evergreen.V48.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V48.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
