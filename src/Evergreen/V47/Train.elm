module Evergreen.V47.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V47.Coord
import Evergreen.V47.Id
import Evergreen.V47.Tile
import Evergreen.V47.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
    , path : Evergreen.V47.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
        , path : Evergreen.V47.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V47.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
        , homePath : Evergreen.V47.Tile.RailPath
        , isStuck : Maybe Effect.Time.Posix
        , status : Status
        , owner : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
                , path : Evergreen.V47.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V47.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuck : FieldChanged (Maybe Effect.Time.Posix)
        , status : FieldChanged Status
        }
