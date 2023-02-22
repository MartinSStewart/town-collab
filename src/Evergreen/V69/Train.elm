module Evergreen.V69.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V69.Coord
import Evergreen.V69.Id
import Evergreen.V69.Tile
import Evergreen.V69.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    , path : Evergreen.V69.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
        , path : Evergreen.V69.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V69.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
        , homePath : Evergreen.V69.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
                , path : Evergreen.V69.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V69.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
