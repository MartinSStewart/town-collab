module Evergreen.V2.Change exposing (..)

import Dict
import Evergreen.V2.Bounds
import Evergreen.V2.Coord
import Evergreen.V2.Grid
import Evergreen.V2.GridCell
import Evergreen.V2.Id
import Evergreen.V2.Units


type LocalChange
    = LocalGridChange Evergreen.V2.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId) (Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    | LocalToggleUserVisibilityForAll (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)


type ServerChange
    = ServerGridChange Evergreen.V2.Grid.GridChange
    | ServerUndoPoint
        { userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V2.Coord.RawCellCoord Int
        }
    | ServerToggleUserVisibilityForAll (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V2.Bounds.Bounds Evergreen.V2.Units.CellUnit) (List ( Evergreen.V2.Coord.Coord Evergreen.V2.Units.CellUnit, Evergreen.V2.GridCell.Cell ))


type Change
    = LocalChange LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange
