module Evergreen.V8.Change exposing (..)

import Dict
import Evergreen.V8.Bounds
import Evergreen.V8.Coord
import Evergreen.V8.Grid
import Evergreen.V8.GridCell
import Evergreen.V8.Id
import Evergreen.V8.Units


type LocalChange
    = LocalGridChange Evergreen.V8.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) (Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | LocalToggleUserVisibilityForAll (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)


type ServerChange
    = ServerGridChange Evergreen.V8.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V8.Coord.RawCellCoord Int
        }
    | ServerToggleUserVisibilityForAll (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V8.Bounds.Bounds Evergreen.V8.Units.CellUnit) (List ( Evergreen.V8.Coord.Coord Evergreen.V8.Units.CellUnit, Evergreen.V8.GridCell.CellData ))


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
