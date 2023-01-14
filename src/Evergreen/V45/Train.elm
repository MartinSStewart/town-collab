module Evergreen.V45.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V45.Coord
import Evergreen.V45.Id
import Evergreen.V45.Tile
import Evergreen.V45.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
    , path : Evergreen.V45.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
        , path : Evergreen.V45.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V45.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
        , homePath : Evergreen.V45.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
                , path : Evergreen.V45.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V45.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
