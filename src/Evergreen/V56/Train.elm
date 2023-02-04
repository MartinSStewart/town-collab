module Evergreen.V56.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V56.Coord
import Evergreen.V56.Id
import Evergreen.V56.Tile
import Evergreen.V56.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
    , path : Evergreen.V56.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
        , path : Evergreen.V56.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V56.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
        , homePath : Evergreen.V56.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
                , path : Evergreen.V56.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V56.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
