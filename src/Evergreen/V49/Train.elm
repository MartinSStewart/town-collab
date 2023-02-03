module Evergreen.V49.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V49.Coord
import Evergreen.V49.Id
import Evergreen.V49.Tile
import Evergreen.V49.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
    , path : Evergreen.V49.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
        , path : Evergreen.V49.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V49.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
        , homePath : Evergreen.V49.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
                , path : Evergreen.V49.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V49.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
