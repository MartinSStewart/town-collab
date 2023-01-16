module Change exposing (Change(..), ClientChange(..), Cow, FrontendUser, LocalChange(..), LoggedIn_, ServerChange(..), UserStatus(..))

import Bounds exposing (Bounds)
import Color exposing (Color, Colors)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Effect.Time
import Grid
import GridCell
import Id exposing (CowId, EventId, Id, UserId)
import MailEditor exposing (MailEditorData)
import Point2d exposing (Point2d)
import Units exposing (CellUnit, WorldUnit)


type Change
    = LocalChange (Id EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type LocalChange
    = LocalGridChange Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Id CowId) (Point2d WorldUnit WorldUnit) Effect.Time.Posix
    | DropCow (Id CowId) (Point2d WorldUnit WorldUnit) Effect.Time.Posix
    | MoveCursor (Point2d WorldUnit WorldUnit)
    | InvalidChange
    | ChangeHandColor Colors
    | ToggleRailSplit (Coord WorldUnit)
    | ChangeDisplayName DisplayName


type ClientChange
    = ViewBoundsChange (Bounds CellUnit) (List ( Coord CellUnit, GridCell.CellData ))


type ServerChange
    = ServerGridChange { gridChange : Grid.GridChange, newCells : List (Coord CellUnit) }
    | ServerUndoPoint { userId : Id UserId, undoPoints : Dict RawCellCoord Int }
    | ServerPickupCow (Id UserId) (Id CowId) (Point2d WorldUnit WorldUnit) Effect.Time.Posix
    | ServerDropCow (Id UserId) (Id CowId) (Point2d WorldUnit WorldUnit)
    | ServerMoveCursor (Id UserId) (Point2d WorldUnit WorldUnit)
    | ServerUserDisconnected (Id UserId)
    | ServerUserConnected (Id UserId) FrontendUser
    | ServerYouLoggedIn LoggedIn_ FrontendUser
    | ServerChangeHandColor (Id UserId) Colors
    | ServerToggleRailSplit (Coord WorldUnit)
    | ServerChangeDisplayName (Id UserId) DisplayName


type alias FrontendUser =
    { name : DisplayName
    , handColor : Colors
    }


type alias Cow =
    { position : Point2d WorldUnit WorldUnit
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias LoggedIn_ =
    { userId : Id UserId
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , mailEditor : MailEditorData
    }
