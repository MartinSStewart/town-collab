module Change exposing (Change(..), ClientChange(..), Cow, LocalChange(..), ServerChange(..))

import Bounds exposing (Bounds)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import Grid
import GridCell
import Id exposing (CowId, EventId, Id, UserId)
import IdDict exposing (IdDict)
import Point2d exposing (Point2d)
import Time
import Units exposing (CellUnit, WorldUnit)


type Change
    = LocalChange (Id EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type LocalChange
    = LocalGridChange Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Id UserId) (Coord WorldUnit)
    | LocalUnhideUser (Id UserId)
    | PickupCow (Id CowId) (Point2d WorldUnit WorldUnit) Time.Posix
    | DropCow (Id CowId) (Point2d WorldUnit WorldUnit) Time.Posix
    | MoveCursor (Point2d WorldUnit WorldUnit)
    | InvalidChange


type ClientChange
    = ViewBoundsChange (Bounds CellUnit) (List ( Coord CellUnit, GridCell.CellData ))


type ServerChange
    = ServerGridChange { gridChange : Grid.GridChange, newCells : List (Coord CellUnit) }
    | ServerUndoPoint { userId : Id UserId, undoPoints : Dict RawCellCoord Int }
    | ServerPickupCow (Id UserId) (Id CowId) (Point2d WorldUnit WorldUnit) Time.Posix
    | ServerDropCow (Id UserId) (Id CowId) (Point2d WorldUnit WorldUnit)
    | ServerMoveCursor (Id UserId) (Point2d WorldUnit WorldUnit)


type alias Cow =
    { position : Point2d WorldUnit WorldUnit
    }
