module Evergreen.V43.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V43.Bounds
import Evergreen.V43.Color
import Evergreen.V43.Coord
import Evergreen.V43.Grid
import Evergreen.V43.GridCell
import Evergreen.V43.Id
import Evergreen.V43.MailEditor
import Evergreen.V43.Point2d
import Evergreen.V43.Units


type LocalChange
    = LocalGridChange Evergreen.V43.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V43.Id.Id Evergreen.V43.Id.CowId) (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V43.Id.Id Evergreen.V43.Id.CowId) (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V43.Color.Colors
    | ToggleRailSplit (Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit)


type alias LoggedIn_ =
    { userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V43.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V43.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V43.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V43.MailEditor.MailEditorData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V43.Grid.GridChange
        , newCells : List (Evergreen.V43.Coord.Coord Evergreen.V43.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V43.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId) (Evergreen.V43.Id.Id Evergreen.V43.Id.CowId) (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId) (Evergreen.V43.Id.Id Evergreen.V43.Id.CowId) (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId) (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId)
    | ServerUserConnected (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId) Evergreen.V43.Color.Colors
    | ServerYouLoggedIn LoggedIn_ Evergreen.V43.Color.Colors
    | ServerChangeHandColor (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId) Evergreen.V43.Color.Colors
    | ServerToggleRailSplit (Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit)


type ClientChange
    = ViewBoundsChange (Evergreen.V43.Bounds.Bounds Evergreen.V43.Units.CellUnit) (List ( Evergreen.V43.Coord.Coord Evergreen.V43.Units.CellUnit, Evergreen.V43.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V43.Id.Id Evergreen.V43.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit
    }
