module Evergreen.V52.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V52.Coord
import Evergreen.V52.Id
import Evergreen.V52.Tile
import Evergreen.V52.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
    , path : Evergreen.V52.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
        , path : Evergreen.V52.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V52.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
        , homePath : Evergreen.V52.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
                , path : Evergreen.V52.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V52.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
