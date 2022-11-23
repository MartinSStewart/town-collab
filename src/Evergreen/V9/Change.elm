module Evergreen.V9.Change exposing (..)

import Dict
import Evergreen.V9.Bounds
import Evergreen.V9.Coord
import Evergreen.V9.Grid
import Evergreen.V9.GridCell
import Evergreen.V9.Id
import Evergreen.V9.Units


type LocalChange
    = LocalGridChange Evergreen.V9.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | LocalToggleUserVisibilityForAll (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)


type ServerChange
    = ServerGridChange Evergreen.V9.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V9.Coord.RawCellCoord Int
        }
    | ServerToggleUserVisibilityForAll (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V9.Bounds.Bounds Evergreen.V9.Units.CellUnit) (List ( Evergreen.V9.Coord.Coord Evergreen.V9.Units.CellUnit, Evergreen.V9.GridCell.CellData ))


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
