module Evergreen.V25.Train exposing (..)

import Duration
import Evergreen.V25.Coord
import Evergreen.V25.Id
import Evergreen.V25.Tile
import Evergreen.V25.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
    , path : Evergreen.V25.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
        , path : Evergreen.V25.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V25.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
        , homePath : Evergreen.V25.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
                , path : Evergreen.V25.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V25.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
