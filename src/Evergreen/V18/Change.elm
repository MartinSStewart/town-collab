module Evergreen.V18.Change exposing (..)

import Dict
import Evergreen.V18.Bounds
import Evergreen.V18.Coord
import Evergreen.V18.Grid
import Evergreen.V18.GridCell
import Evergreen.V18.Id
import Evergreen.V18.Units


type LocalChange
    = LocalGridChange Evergreen.V18.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId) (Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V18.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V18.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V18.Bounds.Bounds Evergreen.V18.Units.CellUnit) (List ( Evergreen.V18.Coord.Coord Evergreen.V18.Units.CellUnit, Evergreen.V18.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V18.Id.Id Evergreen.V18.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
