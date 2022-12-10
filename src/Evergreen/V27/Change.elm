module Evergreen.V27.Change exposing (..)

import Dict
import Evergreen.V27.Bounds
import Evergreen.V27.Coord
import Evergreen.V27.Grid
import Evergreen.V27.GridCell
import Evergreen.V27.Id
import Evergreen.V27.Units


type LocalChange
    = LocalGridChange Evergreen.V27.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V27.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V27.Coord.RawCellCoord Int
        }


type ClientChange
    = ViewBoundsChange (Evergreen.V27.Bounds.Bounds Evergreen.V27.Units.CellUnit) (List ( Evergreen.V27.Coord.Coord Evergreen.V27.Units.CellUnit, Evergreen.V27.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V27.Id.Id Evergreen.V27.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
