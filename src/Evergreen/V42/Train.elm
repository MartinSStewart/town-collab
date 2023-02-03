module Evergreen.V42.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V42.Coord
import Evergreen.V42.Id
import Evergreen.V42.Tile
import Evergreen.V42.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
    , path : Evergreen.V42.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
        , path : Evergreen.V42.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V42.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
        , homePath : Evergreen.V42.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
                , path : Evergreen.V42.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V42.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
