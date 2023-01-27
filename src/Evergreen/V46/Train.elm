module Evergreen.V46.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V46.Coord
import Evergreen.V46.Id
import Evergreen.V46.Tile
import Evergreen.V46.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
    , path : Evergreen.V46.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
        , path : Evergreen.V46.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V46.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
        , homePath : Evergreen.V46.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
                , path : Evergreen.V46.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V46.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
