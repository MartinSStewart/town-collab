module Evergreen.V29.Change exposing (..)

import Dict
import Evergreen.V29.Bounds
import Evergreen.V29.Coord
import Evergreen.V29.Grid
import Evergreen.V29.GridCell
import Evergreen.V29.Id
import Evergreen.V29.Point2d
import Evergreen.V29.Units
import Time


type LocalChange
    = LocalGridChange Evergreen.V29.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | PickupCow (Evergreen.V29.Id.Id Evergreen.V29.Id.CowId) (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit) Time.Posix
    | DropCow (Evergreen.V29.Id.Id Evergreen.V29.Id.CowId) (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit) Time.Posix
    | MoveCursor (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit)
    | InvalidChange


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V29.Grid.GridChange
        , newCells : List (Evergreen.V29.Coord.Coord Evergreen.V29.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V29.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.CowId) (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit) Time.Posix
    | ServerDropCow (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.CowId) (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit)


type ClientChange
    = ViewBoundsChange (Evergreen.V29.Bounds.Bounds Evergreen.V29.Units.CellUnit) (List ( Evergreen.V29.Coord.Coord Evergreen.V29.Units.CellUnit, Evergreen.V29.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V29.Id.Id Evergreen.V29.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type alias Cow =
    { position : Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit
    }
