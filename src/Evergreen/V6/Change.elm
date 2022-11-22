module Evergreen.V6.Change exposing (..)

import Dict
import Evergreen.V6.Bounds
import Evergreen.V6.Coord
import Evergreen.V6.Grid
import Evergreen.V6.GridCell
import Evergreen.V6.Id
import Evergreen.V6.Units


type LocalChange
    = LocalGridChange Evergreen.V6.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) (Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | LocalToggleUserVisibilityForAll (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)


type ServerChange
    = ServerGridChange Evergreen.V6.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V6.Coord.RawCellCoord Int
        }
    | ServerToggleUserVisibilityForAll (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V6.Bounds.Bounds Evergreen.V6.Units.CellUnit) (List ( Evergreen.V6.Coord.Coord Evergreen.V6.Units.CellUnit, Evergreen.V6.GridCell.CellData ))


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
