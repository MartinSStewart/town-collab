module Evergreen.V11.Train exposing (..)

import Duration
import Evergreen.V11.Coord
import Evergreen.V11.Id
import Evergreen.V11.Tile
import Evergreen.V11.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
    , path : Evergreen.V11.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
        , path : Evergreen.V11.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V11.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
        , homePath : Evergreen.V11.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : FieldChanged (Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit)
        , path : FieldChanged Evergreen.V11.Tile.RailPath
        , previousPaths : FieldChanged (List PreviousPath)
        , t : FieldChanged Float
        , speed : FieldChanged (Quantity.Quantity Float (Quantity.Rate Evergreen.V11.Units.TileLocalUnit Duration.Seconds))
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
