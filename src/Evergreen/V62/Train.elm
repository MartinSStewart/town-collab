module Evergreen.V62.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V62.Coord
import Evergreen.V62.Id
import Evergreen.V62.Tile
import Evergreen.V62.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
    , path : Evergreen.V62.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
        , path : Evergreen.V62.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V62.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
        , homePath : Evergreen.V62.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
                , path : Evergreen.V62.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V62.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
