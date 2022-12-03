module Evergreen.V17.Change exposing (..)

import Dict
import Evergreen.V17.Bounds
import Evergreen.V17.Coord
import Evergreen.V17.Grid
import Evergreen.V17.GridCell
import Evergreen.V17.Id
import Evergreen.V17.Units


type LocalChange
    = LocalGridChange Evergreen.V17.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | LocalHideUser (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    | LocalUnhideUser (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    | InvalidChange


type ServerChange
    = ServerGridChange Evergreen.V17.Grid.GridChange
    | ServerUndoPoint 
    { userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , undoPoints : (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int)
    }


type ClientChange
    = ViewBoundsChange (Evergreen.V17.Bounds.Bounds Evergreen.V17.Units.CellUnit) (List ((Evergreen.V17.Coord.Coord Evergreen.V17.Units.CellUnit), Evergreen.V17.GridCell.CellData))


type Change
    = LocalChange (Evergreen.V17.Id.Id Evergreen.V17.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange