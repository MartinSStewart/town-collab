module Evergreen.V60.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V60.Coord
import Evergreen.V60.Id
import Evergreen.V60.Tile
import Evergreen.V60.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
    , path : Evergreen.V60.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
        , path : Evergreen.V60.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V60.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
        , homePath : Evergreen.V60.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
                , path : Evergreen.V60.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V60.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
