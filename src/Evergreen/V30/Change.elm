module Evergreen.V30.Change exposing (..)

import Dict
import Evergreen.V30.Bounds
import Evergreen.V30.Color
import Evergreen.V30.Coord
import Evergreen.V30.Grid
import Evergreen.V30.GridCell
import Evergreen.V30.Id
import Evergreen.V30.Point2d
import Evergreen.V30.Units
import Time


type LocalChange
    = LocalGridChange Evergreen.V30.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | PickupCow (Evergreen.V30.Id.Id Evergreen.V30.Id.CowId) (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit) Time.Posix
    | DropCow (Evergreen.V30.Id.Id Evergreen.V30.Id.CowId) (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit) Time.Posix
    | MoveCursor (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V30.Color.Colors


type ServerChange
    = ServerGridChange 
    { gridChange : Evergreen.V30.Grid.GridChange
    , newCells : (List (Evergreen.V30.Coord.Coord Evergreen.V30.Units.CellUnit))
    }
    | ServerUndoPoint 
    { userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , undoPoints : (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int)
    }
    | ServerPickupCow (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.CowId) (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit) Time.Posix
    | ServerDropCow (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.CowId) (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | ServerUserConnected (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.Color.Colors
    | ServerChangeHandColor (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.Color.Colors


type ClientChange
    = ViewBoundsChange (Evergreen.V30.Bounds.Bounds Evergreen.V30.Units.CellUnit) (List ((Evergreen.V30.Coord.Coord Evergreen.V30.Units.CellUnit), Evergreen.V30.GridCell.CellData))


type Change
    = LocalChange (Evergreen.V30.Id.Id Evergreen.V30.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type alias Cow = 
    { position : (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    }