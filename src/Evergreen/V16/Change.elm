module Evergreen.V16.Change exposing (..)

import Dict
import Evergreen.V16.Bounds
import Evergreen.V16.Coord
import Evergreen.V16.Grid
import Evergreen.V16.GridCell
import Evergreen.V16.Id
import Evergreen.V16.Units


type LocalChange
    = LocalGridChange Evergreen.V16.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V16.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V16.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V16.Bounds.Bounds Evergreen.V16.Units.CellUnit) (List ( Evergreen.V16.Coord.Coord Evergreen.V16.Units.CellUnit, Evergreen.V16.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V16.Id.Id Evergreen.V16.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
