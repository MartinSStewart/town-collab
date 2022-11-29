module Evergreen.V15.Change exposing (..)

import Dict
import Evergreen.V15.Bounds
import Evergreen.V15.Coord
import Evergreen.V15.Grid
import Evergreen.V15.GridCell
import Evergreen.V15.Id
import Evergreen.V15.Units


type LocalChange
    = LocalGridChange Evergreen.V15.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V15.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V15.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V15.Bounds.Bounds Evergreen.V15.Units.CellUnit) (List ( Evergreen.V15.Coord.Coord Evergreen.V15.Units.CellUnit, Evergreen.V15.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V15.Id.Id Evergreen.V15.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
