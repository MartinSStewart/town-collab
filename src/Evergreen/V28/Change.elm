module Evergreen.V28.Change exposing (..)

import Dict
import Evergreen.V28.Bounds
import Evergreen.V28.Coord
import Evergreen.V28.Grid
import Evergreen.V28.GridCell
import Evergreen.V28.Id
import Evergreen.V28.Units


type LocalChange
    = LocalGridChange Evergreen.V28.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId) (Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V28.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V28.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V28.Bounds.Bounds Evergreen.V28.Units.CellUnit) (List ( Evergreen.V28.Coord.Coord Evergreen.V28.Units.CellUnit, Evergreen.V28.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V28.Id.Id Evergreen.V28.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
