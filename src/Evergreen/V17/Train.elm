module Evergreen.V17.Train exposing (..)

import Duration
import Evergreen.V17.Coord
import Evergreen.V17.Id
import Evergreen.V17.Tile
import Evergreen.V17.Units
import Quantity
import Time


type alias PreviousPath = 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , path : Evergreen.V17.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice 
    { time : Time.Posix
    , userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    }


type Train
    = Train 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , path : Evergreen.V17.Tile.RailPath
    , previousPaths : (List PreviousPath)
    , t : Float
    , speed : (Quantity.Quantity Float (Quantity.Rate Evergreen.V17.Units.TileLocalUnit Duration.Seconds))
    , home : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , homePath : Evergreen.V17.Tile.RailPath
    , isStuck : (Maybe Time.Posix)
    , status : Status
    , owner : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged 
    { position : (FieldChanged 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , path : Evergreen.V17.Tile.RailPath
    , previousPaths : (List PreviousPath)
    , t : Float
    , speed : (Quantity.Quantity Float (Quantity.Rate Evergreen.V17.Units.TileLocalUnit Duration.Seconds))
    })
    , isStuck : (FieldChanged (Maybe Time.Posix))
    , status : (FieldChanged Status)
    }