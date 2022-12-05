module Evergreen.V20.Change exposing (..)

import Dict
import Evergreen.V20.Bounds
import Evergreen.V20.Coord
import Evergreen.V20.Grid
import Evergreen.V20.GridCell
import Evergreen.V20.Id
import Evergreen.V20.Units


type LocalChange
    = LocalGridChange Evergreen.V20.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId) (Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V20.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V20.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V20.Bounds.Bounds Evergreen.V20.Units.CellUnit) (List ( Evergreen.V20.Coord.Coord Evergreen.V20.Units.CellUnit, Evergreen.V20.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V20.Id.Id Evergreen.V20.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
