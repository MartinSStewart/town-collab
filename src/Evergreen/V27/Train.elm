module Evergreen.V27.Train exposing (..)

import Duration
import Evergreen.V27.Coord
import Evergreen.V27.Id
import Evergreen.V27.Tile
import Evergreen.V27.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
    , path : Evergreen.V27.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
        , path : Evergreen.V27.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V27.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
        , homePath : Evergreen.V27.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
                , path : Evergreen.V27.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V27.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
