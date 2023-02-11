module Evergreen.V58.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V58.Coord
import Evergreen.V58.Id
import Evergreen.V58.Tile
import Evergreen.V58.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
    , path : Evergreen.V58.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
        , path : Evergreen.V58.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V58.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
        , homePath : Evergreen.V58.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
                , path : Evergreen.V58.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V58.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
