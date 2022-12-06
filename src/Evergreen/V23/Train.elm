module Evergreen.V23.Train exposing (..)

import Duration
import Evergreen.V23.Coord
import Evergreen.V23.Id
import Evergreen.V23.Tile
import Evergreen.V23.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
    , path : Evergreen.V23.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
        , path : Evergreen.V23.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V23.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
        , homePath : Evergreen.V23.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
                , path : Evergreen.V23.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V23.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
