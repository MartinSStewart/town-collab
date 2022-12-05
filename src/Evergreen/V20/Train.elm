module Evergreen.V20.Train exposing (..)

import Duration
import Evergreen.V20.Coord
import Evergreen.V20.Id
import Evergreen.V20.Tile
import Evergreen.V20.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
    , path : Evergreen.V20.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
        , path : Evergreen.V20.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V20.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
        , homePath : Evergreen.V20.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
                , path : Evergreen.V20.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V20.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
