module Change exposing (Change(..), ClientChange(..), LocalChange(..), ServerChange(..))

import Bounds exposing (Bounds)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import Grid
import GridCell
import NotifyMe
import Units exposing (CellUnit, TileUnit)
import User exposing (UserId)


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type LocalChange
    = LocalGridChange Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser UserId (Coord TileUnit)
    | LocalUnhideUser UserId
    | LocalToggleUserVisibilityForAll UserId


type ClientChange
    = ViewBoundsChange (Bounds CellUnit) (List ( Coord CellUnit, GridCell.Cell ))


type ServerChange
    = ServerGridChange Grid.GridChange
    | ServerUndoPoint { userId : UserId, undoPoints : Dict RawCellCoord Int }
    | ServerToggleUserVisibilityForAll UserId
