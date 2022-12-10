module Evergreen.V26.Change exposing (..)

import Dict
import Evergreen.V26.Bounds
import Evergreen.V26.Coord
import Evergreen.V26.Grid
import Evergreen.V26.GridCell
import Evergreen.V26.Id
import Evergreen.V26.Units


type LocalChange
    = LocalGridChange Evergreen.V26.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V26.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V26.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V26.Bounds.Bounds Evergreen.V26.Units.CellUnit) (List ( Evergreen.V26.Coord.Coord Evergreen.V26.Units.CellUnit, Evergreen.V26.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V26.Id.Id Evergreen.V26.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
