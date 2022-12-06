module Evergreen.V23.Change exposing (..)

import Dict
import Evergreen.V23.Bounds
import Evergreen.V23.Coord
import Evergreen.V23.Grid
import Evergreen.V23.GridCell
import Evergreen.V23.Id
import Evergreen.V23.Units


type LocalChange
    = LocalGridChange Evergreen.V23.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V23.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V23.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V23.Bounds.Bounds Evergreen.V23.Units.CellUnit) (List ( Evergreen.V23.Coord.Coord Evergreen.V23.Units.CellUnit, Evergreen.V23.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V23.Id.Id Evergreen.V23.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
