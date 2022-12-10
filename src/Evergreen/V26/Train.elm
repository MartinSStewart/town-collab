module Evergreen.V26.Train exposing (..)

import Duration
import Evergreen.V26.Coord
import Evergreen.V26.Id
import Evergreen.V26.Tile
import Evergreen.V26.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
    , path : Evergreen.V26.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
        , path : Evergreen.V26.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V26.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
        , homePath : Evergreen.V26.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
                , path : Evergreen.V26.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V26.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
