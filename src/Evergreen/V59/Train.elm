module Evergreen.V59.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V59.Coord
import Evergreen.V59.Id
import Evergreen.V59.Tile
import Evergreen.V59.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
    , path : Evergreen.V59.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
        , path : Evergreen.V59.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V59.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
        , homePath : Evergreen.V59.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
                , path : Evergreen.V59.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V59.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
