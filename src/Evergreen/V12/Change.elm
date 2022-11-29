module Evergreen.V12.Change exposing (..)

import Dict
import Evergreen.V12.Bounds
import Evergreen.V12.Coord
import Evergreen.V12.Grid
import Evergreen.V12.GridCell
import Evergreen.V12.Id
import Evergreen.V12.Units


type LocalChange
    = LocalGridChange Evergreen.V12.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V12.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V12.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V12.Bounds.Bounds Evergreen.V12.Units.CellUnit) (List ( Evergreen.V12.Coord.Coord Evergreen.V12.Units.CellUnit, Evergreen.V12.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V12.Id.Id Evergreen.V12.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
