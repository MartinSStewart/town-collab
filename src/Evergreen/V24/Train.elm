module Evergreen.V24.Train exposing (..)

import Duration
import Evergreen.V24.Coord
import Evergreen.V24.Id
import Evergreen.V24.Tile
import Evergreen.V24.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
    , path : Evergreen.V24.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
        , path : Evergreen.V24.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V24.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
        , homePath : Evergreen.V24.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
                , path : Evergreen.V24.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V24.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
