module Evergreen.V125.Train exposing (..)

import Duration
import Effect.Time
import Evergreen.V125.Color
import Evergreen.V125.Coord
import Evergreen.V125.Id
import Evergreen.V125.Tile
import Evergreen.V125.Units
import Quantity


type alias PreviousPath =
    { position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , path : Evergreen.V125.Tile.RailPath
    , reversed : Bool
    }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId)
    | IsNotStuckOrDerailed


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
        { startedAt : Effect.Time.Posix
        }
    | StoppedAtPostOffice
        { time : Effect.Time.Posix
        , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        }


type Train
    = Train
        { position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
        , path : Evergreen.V125.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V125.Units.TileLocalUnit Duration.Seconds)
        , home : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
        , homePath : Evergreen.V125.Tile.RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , color : Evergreen.V125.Color.Color
        }


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
        , path : Evergreen.V125.Tile.RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity.Quantity Float (Quantity.Rate Evergreen.V125.Units.TileLocalUnit Duration.Seconds)
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        }
