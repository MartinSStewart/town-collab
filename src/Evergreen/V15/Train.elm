module Evergreen.V15.Train exposing (..)

import Duration
import Evergreen.V15.Coord
import Evergreen.V15.Id
import Evergreen.V15.Tile
import Evergreen.V15.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
    , path : Evergreen.V15.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
        , path : Evergreen.V15.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V15.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
        , homePath : Evergreen.V15.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
                , path : Evergreen.V15.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V15.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
