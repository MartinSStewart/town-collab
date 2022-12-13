module Evergreen.V29.Train exposing (..)

import Duration
import Evergreen.V29.Coord
import Evergreen.V29.Id
import Evergreen.V29.Tile
import Evergreen.V29.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
    , path : Evergreen.V29.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
        , path : Evergreen.V29.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V29.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
        , homePath : Evergreen.V29.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
                , path : Evergreen.V29.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V29.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
