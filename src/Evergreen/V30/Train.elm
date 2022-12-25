module Evergreen.V30.Train exposing (..)

import Duration
import Evergreen.V30.Coord
import Evergreen.V30.Id
import Evergreen.V30.Tile
import Evergreen.V30.Units
import Quantity
import Time


type alias PreviousPath = 
    { position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , path : Evergreen.V30.Tile.RailPath
    , reversed : Bool
    }


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice 
    { time : Time.Posix
    , userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    }


type Train
    = Train 
    { position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , path : Evergreen.V30.Tile.RailPath
    , previousPaths : (List PreviousPath)
    , t : Float
    , speed : (Quantity.Quantity Float (Quantity.Rate Evergreen.V30.Units.TileLocalUnit Duration.Seconds))
    , home : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , homePath : Evergreen.V30.Tile.RailPath
    , isStuck : (Maybe Time.Posix)
    , status : Status
    , owner : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    }


type FieldChanged a
    = FieldChanged a
    | Unchanged


type TrainDiff
    = NewTrain Train
    | TrainChanged 
    { position : (FieldChanged 
    { position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , path : Evergreen.V30.Tile.RailPath
    , previousPaths : (List PreviousPath)
    , t : Float
    , speed : (Quantity.Quantity Float (Quantity.Rate Evergreen.V30.Units.TileLocalUnit Duration.Seconds))
    })
    , isStuck : (FieldChanged (Maybe Time.Posix))
    , status : (FieldChanged Status)
    }