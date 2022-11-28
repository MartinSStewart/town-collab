module Evergreen.V11.Change exposing (..)

import Dict
import Evergreen.V11.Bounds
import Evergreen.V11.Coord
import Evergreen.V11.Grid
import Evergreen.V11.GridCell
import Evergreen.V11.Id
import Evergreen.V11.Units


type LocalChange
    = LocalGridChange Evergreen.V11.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId) (Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V11.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V11.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V11.Bounds.Bounds Evergreen.V11.Units.CellUnit) (List ( Evergreen.V11.Coord.Coord Evergreen.V11.Units.CellUnit, Evergreen.V11.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V11.Id.Id Evergreen.V11.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
