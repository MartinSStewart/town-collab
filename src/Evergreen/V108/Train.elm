module Evergreen.V108.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V108.Color
import Evergreen.V108.Coord
import Evergreen.V108.Id
import Evergreen.V108.Tile
import Evergreen.V108.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , path : Evergreen.V108.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
        , path : Evergreen.V108.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V108.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
        , homePath : Evergreen.V108.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , color : Evergreen.V108.Color.Color
        }


type FieldChanged a
    = FieldChanged a


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
                , path : Evergreen.V108.Tile.RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V108.Units.TileLocalUnit Duration.Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }
