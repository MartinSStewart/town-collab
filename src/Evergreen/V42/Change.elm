module Evergreen.V42.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V42.Bounds
import Evergreen.V42.Color
import Evergreen.V42.Coord
import Evergreen.V42.Grid
import Evergreen.V42.GridCell
import Evergreen.V42.Id
import Evergreen.V42.MailEditor
import Evergreen.V42.Point2d
import Evergreen.V42.Units


type LocalChange
    = LocalGridChange Evergreen.V42.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V42.Id.Id Evergreen.V42.Id.CowId) (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V42.Id.Id Evergreen.V42.Id.CowId) (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V42.Color.Colors
    | ToggleRailSplit (Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit)


type alias LoggedIn_ =
    { userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V42.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V42.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V42.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V42.MailEditor.MailEditorData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V42.Grid.GridChange
        , newCells : List (Evergreen.V42.Coord.Coord Evergreen.V42.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V42.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.Id.Id Evergreen.V42.Id.CowId) (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.Id.Id Evergreen.V42.Id.CowId) (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
    | ServerUserConnected (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Color.Colors
    | ServerYouLoggedIn LoggedIn_ Evergreen.V42.Color.Colors
    | ServerChangeHandColor (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) Evergreen.V42.Color.Colors
    | ServerToggleRailSplit (Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit)


type ClientChange
    = ViewBoundsChange (Evergreen.V42.Bounds.Bounds Evergreen.V42.Units.CellUnit) (List ( Evergreen.V42.Coord.Coord Evergreen.V42.Units.CellUnit, Evergreen.V42.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V42.Id.Id Evergreen.V42.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit
    }
