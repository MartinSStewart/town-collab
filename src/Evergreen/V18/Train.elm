module Evergreen.V18.Train exposing (..)

import Duration
import Evergreen.V18.Coord
import Evergreen.V18.Id
import Evergreen.V18.Tile
import Evergreen.V18.Units
import Quantity
import Time


type alias PreviousPath =
    { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
    , path : Evergreen.V18.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Time.Posix
        , userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
        , path : Evergreen.V18.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V18.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
        , homePath : Evergreen.V18.Tile.RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        , owner : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
                , path : Evergreen.V18.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V18.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Time.Posix)
        , status : FieldChanged Status
        }
