module Evergreen.V1.Change exposing (..)

import Dict
import Evergreen.V1.Bounds
import Evergreen.V1.Coord
import Evergreen.V1.Grid
import Evergreen.V1.GridCell
import Evergreen.V1.Units
import Evergreen.V1.User


type LocalChange
    = LocalGridChange Evergreen.V1.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser Evergreen.V1.User.UserId (Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit)
    | LocalUnhideUser Evergreen.V1.User.UserId
    | LocalToggleUserVisibilityForAll Evergreen.V1.User.UserId


type ServerChange
    = ServerGridChange Evergreen.V1.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V1.User.UserId
        , undoPoints : Dict.Dict Evergreen.V1.Coord.RawCellCoord Int
        }
    | ServerToggleUserVisibilityForAll Evergreen.V1.User.UserId


type ClientChange
    = ViewBoundsChange (Evergreen.V1.Bounds.Bounds Evergreen.V1.Units.CellUnit) (List ( Evergreen.V1.Coord.Coord Evergreen.V1.Units.CellUnit, Evergreen.V1.GridCell.Cell ))


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
