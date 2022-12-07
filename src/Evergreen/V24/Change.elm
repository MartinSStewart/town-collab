module Evergreen.V24.Change exposing (..)

import Dict
import Evergreen.V24.Bounds
import Evergreen.V24.Coord
import Evergreen.V24.Grid
import Evergreen.V24.GridCell
import Evergreen.V24.Id
import Evergreen.V24.Units


type LocalChange
    = LocalGridChange Evergreen.V24.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V24.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V24.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V24.Bounds.Bounds Evergreen.V24.Units.CellUnit) (List ( Evergreen.V24.Coord.Coord Evergreen.V24.Units.CellUnit, Evergreen.V24.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V24.Id.Id Evergreen.V24.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
