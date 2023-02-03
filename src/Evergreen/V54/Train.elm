module Evergreen.V54.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V54.Coord
import Evergreen.V54.Id
import Evergreen.V54.Tile
import Evergreen.V54.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit
    , path : Evergreen.V54.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit
        , path : Evergreen.V54.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V54.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit
        , homePath : Evergreen.V54.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit
                , path : Evergreen.V54.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V54.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
