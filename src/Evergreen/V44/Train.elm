module Evergreen.V44.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V44.Coord
import Evergreen.V44.Id
import Evergreen.V44.Tile
import Evergreen.V44.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
    , path : Evergreen.V44.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
        , path : Evergreen.V44.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V44.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
        , homePath : Evergreen.V44.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
                , path : Evergreen.V44.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V44.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
