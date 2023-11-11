module Evergreen.V110.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V110.Color
import Evergreen.V110.Coord
import Evergreen.V110.Id
import Evergreen.V110.Tile
import Evergreen.V110.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
    , path : Evergreen.V110.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
        , path : Evergreen.V110.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V110.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
        , homePath : Evergreen.V110.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        , color : Evergreen.V110.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
                , path : Evergreen.V110.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V110.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
