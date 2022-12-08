module Evergreen.V25.Change exposing (..)

import Dict
import Evergreen.V25.Bounds
import Evergreen.V25.Coord
import Evergreen.V25.Grid
import Evergreen.V25.GridCell
import Evergreen.V25.Id
import Evergreen.V25.Units


type LocalChange
    = LocalGridChange Evergreen.V25.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V25.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V25.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V25.Bounds.Bounds Evergreen.V25.Units.CellUnit) (List ( Evergreen.V25.Coord.Coord Evergreen.V25.Units.CellUnit, Evergreen.V25.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V25.Id.Id Evergreen.V25.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
