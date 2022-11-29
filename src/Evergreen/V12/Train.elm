module Evergreen.V12.Train exposing (..)

import Duration
import Evergreen.V12.Coord
import Evergreen.V12.Id
import Evergreen.V12.Tile
import Evergreen.V12.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
    , path : Evergreen.V12.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
        , path : Evergreen.V12.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V12.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
        , homePath : Evergreen.V12.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : FieldChanged (Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit)
        , path : FieldChanged Evergreen.V12.Tile.RailPath
        , previousPaths : FieldChanged (List PreviousPath)
        , t : FieldChanged Float
        , speed : FieldChanged (Quantity.Quantity Float (Quantity.Rate Evergreen.V12.Units.TileLocalUnit Duration.Seconds))
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
