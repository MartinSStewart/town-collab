module Evergreen.V14.Train exposing (..)

import Duration
import Evergreen.V14.Coord
import Evergreen.V14.Id
import Evergreen.V14.Tile
import Evergreen.V14.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
    , path : Evergreen.V14.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
        , path : Evergreen.V14.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V14.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
        , homePath : Evergreen.V14.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : FieldChanged (Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit)
        , path : FieldChanged Evergreen.V14.Tile.RailPath
        , previousPaths : FieldChanged (List PreviousPath)
        , t : FieldChanged Float
        , speed : FieldChanged (Quantity.Quantity Float (Quantity.Rate Evergreen.V14.Units.TileLocalUnit Duration.Seconds))
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
