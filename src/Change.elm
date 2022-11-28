module Change exposing (Change(..), ClientChange(..), LocalChange(..), ServerChange(..))

import Bounds exposing (Bounds)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import Grid
import GridCell
import Id exposing (Id, UserId)
import Units exposing (CellUnit, WorldUnit)


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type LocalChange
    = LocalGridChange Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Id UserId) (Coord WorldUnit)
    | LocalUnhideUser (Id UserId)


type ClientChange
    = ViewBoundsChange (Bounds CellUnit) (List ( Coord CellUnit, GridCell.CellData ))


type ServerChange
    = ServerGridChange Grid.GridChange
    | ServerUndoPoint { userId : Id UserId, undoPoints : Dict RawCellCoord Int }
    | NoOpChange
