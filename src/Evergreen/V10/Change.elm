module Evergreen.V10.Change exposing (..)

import Dict
import Evergreen.V10.Bounds
import Evergreen.V10.Coord
import Evergreen.V10.Grid
import Evergreen.V10.GridCell
import Evergreen.V10.Id
import Evergreen.V10.Units


type LocalChange
    = LocalGridChange Evergreen.V10.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId) (Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    | LocalToggleUserVisibilityForAll (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)


type ServerChange
    = ServerGridChange Evergreen.V10.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V10.Coord.RawCellCoord Int
        }
    | ServerToggleUserVisibilityForAll (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V10.Bounds.Bounds Evergreen.V10.Units.CellUnit) (List ( Evergreen.V10.Coord.Coord Evergreen.V10.Units.CellUnit, Evergreen.V10.GridCell.CellData ))


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
