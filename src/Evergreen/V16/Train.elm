module Evergreen.V16.Train exposing (..)

import Duration
import Evergreen.V16.Coord
import Evergreen.V16.Id
import Evergreen.V16.Tile
import Evergreen.V16.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
    , path : Evergreen.V16.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
        , path : Evergreen.V16.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V16.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
        , homePath : Evergreen.V16.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
                , path : Evergreen.V16.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V16.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
