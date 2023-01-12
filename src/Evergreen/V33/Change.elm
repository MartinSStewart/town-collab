module Evergreen.V33.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V33.Bounds
import Evergreen.V33.Color
import Evergreen.V33.Coord
import Evergreen.V33.Grid
import Evergreen.V33.GridCell
import Evergreen.V33.Id
import Evergreen.V33.MailEditor
import Evergreen.V33.Point2d
import Evergreen.V33.Units


type LocalChange
    = LocalGridChange Evergreen.V33.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V33.Id.Id Evergreen.V33.Id.CowId) (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V33.Id.Id Evergreen.V33.Id.CowId) (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V33.Color.Colors
    | ToggleRailSplit (Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit)


type alias LoggedIn_ =
    { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V33.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V33.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V33.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V33.MailEditor.MailEditorData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V33.Grid.GridChange
        , newCells : List (Evergreen.V33.Coord.Coord Evergreen.V33.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V33.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.CowId) (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.CowId) (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | ServerUserConnected (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Color.Colors
    | ServerYouLoggedIn LoggedIn_ Evergreen.V33.Color.Colors
    | ServerChangeHandColor (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Color.Colors
    | ServerToggleRailSplit (Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit)


type ClientChange
    = ViewBoundsChange (Evergreen.V33.Bounds.Bounds Evergreen.V33.Units.CellUnit) (List ( Evergreen.V33.Coord.Coord Evergreen.V33.Units.CellUnit, Evergreen.V33.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V33.Id.Id Evergreen.V33.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit
    }
