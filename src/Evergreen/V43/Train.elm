module Evergreen.V43.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V43.Coord
import Evergreen.V43.Id
import Evergreen.V43.Tile
import Evergreen.V43.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
    , path : Evergreen.V43.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
        , path : Evergreen.V43.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V43.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
        , homePath : Evergreen.V43.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
                , path : Evergreen.V43.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V43.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
