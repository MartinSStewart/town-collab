module Evergreen.V14.Change exposing (..)

import Dict
import Evergreen.V14.Bounds
import Evergreen.V14.Coord
import Evergreen.V14.Grid
import Evergreen.V14.GridCell
import Evergreen.V14.Id
import Evergreen.V14.Units


type LocalChange
    = LocalGridChange Evergreen.V14.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId) (Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V14.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V14.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V14.Bounds.Bounds Evergreen.V14.Units.CellUnit) (List ( Evergreen.V14.Coord.Coord Evergreen.V14.Units.CellUnit, Evergreen.V14.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V14.Id.Id Evergreen.V14.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
