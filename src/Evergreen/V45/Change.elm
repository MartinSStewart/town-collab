module Evergreen.V45.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V45.Bounds
import Evergreen.V45.Color
import Evergreen.V45.Coord
import Evergreen.V45.Grid
import Evergreen.V45.GridCell
import Evergreen.V45.Id
import Evergreen.V45.MailEditor
import Evergreen.V45.Point2d
import Evergreen.V45.Units


type LocalChange
    = LocalGridChange Evergreen.V45.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V45.Id.Id Evergreen.V45.Id.CowId) (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V45.Id.Id Evergreen.V45.Id.CowId) (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V45.Color.Colors
    | ToggleRailSplit (Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit)


type alias LoggedIn_ =
    { userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V45.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V45.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V45.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V45.MailEditor.MailEditorData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V45.Grid.GridChange
        , newCells : List (Evergreen.V45.Coord.Coord Evergreen.V45.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V45.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.Id.Id Evergreen.V45.Id.CowId) (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.Id.Id Evergreen.V45.Id.CowId) (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
    | ServerUserConnected (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Color.Colors
    | ServerYouLoggedIn LoggedIn_ Evergreen.V45.Color.Colors
    | ServerChangeHandColor (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) Evergreen.V45.Color.Colors
    | ServerToggleRailSplit (Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit)


type ClientChange
    = ViewBoundsChange (Evergreen.V45.Bounds.Bounds Evergreen.V45.Units.CellUnit) (List ( Evergreen.V45.Coord.Coord Evergreen.V45.Units.CellUnit, Evergreen.V45.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V45.Id.Id Evergreen.V45.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit
    }
