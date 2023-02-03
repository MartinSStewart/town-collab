module Evergreen.V44.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V44.Bounds
import Evergreen.V44.Color
import Evergreen.V44.Coord
import Evergreen.V44.Grid
import Evergreen.V44.GridCell
import Evergreen.V44.Id
import Evergreen.V44.MailEditor
import Evergreen.V44.Point2d
import Evergreen.V44.Units


type LocalChange
    = LocalGridChange Evergreen.V44.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V44.Id.Id Evergreen.V44.Id.CowId) (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V44.Id.Id Evergreen.V44.Id.CowId) (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V44.Color.Colors
    | ToggleRailSplit (Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit)


type alias LoggedIn_ =
    { userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V44.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V44.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V44.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V44.MailEditor.MailEditorData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V44.Grid.GridChange
        , newCells : List (Evergreen.V44.Coord.Coord Evergreen.V44.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V44.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId) (Evergreen.V44.Id.Id Evergreen.V44.Id.CowId) (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId) (Evergreen.V44.Id.Id Evergreen.V44.Id.CowId) (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId) (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId)
    | ServerUserConnected (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId) Evergreen.V44.Color.Colors
    | ServerYouLoggedIn LoggedIn_ Evergreen.V44.Color.Colors
    | ServerChangeHandColor (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId) Evergreen.V44.Color.Colors
    | ServerToggleRailSplit (Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit)


type ClientChange
    = ViewBoundsChange (Evergreen.V44.Bounds.Bounds Evergreen.V44.Units.CellUnit) (List ( Evergreen.V44.Coord.Coord Evergreen.V44.Units.CellUnit, Evergreen.V44.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V44.Id.Id Evergreen.V44.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit
    }
