module Evergreen.V28.Train exposing (..)

import Duration
import Evergreen.V28.Coord
import Evergreen.V28.Id
import Evergreen.V28.Tile
import Evergreen.V28.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
    , path : Evergreen.V28.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
        , path : Evergreen.V28.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V28.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
        , homePath : Evergreen.V28.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
                , path : Evergreen.V28.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V28.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
