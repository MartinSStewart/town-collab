module Change exposing
    ( Change(..)
    , ClientChange(..)
    , Cow
    , LocalChange(..)
    , LoggedIn_
    , ServerChange(..)
    , UserStatus(..)
    )

import Bounds exposing (Bounds)
import Color exposing (Color, Colors)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Effect.Time
import EmailAddress exposing (EmailAddress)
import Grid
import GridCell
import Id exposing (CowId, EventId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import MailEditor exposing (MailStatus)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Train exposing (TrainDiff)
import Units exposing (CellUnit, WorldUnit)
import User exposing (FrontendUser)


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
    | SubmitMail { content : List MailEditor.Content, to : Id UserId }
    | UpdateDraft { content : List MailEditor.Content, to : Id UserId }
    | TeleportHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | ViewedMail (Id MailId)
    | SetAllowEmailNotifications Bool


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
    | ServerSubmitMail { from : Id UserId, to : Id UserId }
    | ServerMailStatusChanged (Id MailId) MailStatus
    | ServerTeleportHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (IdDict TrainId TrainDiff)
    | ServerReceivedMail
        { mailId : Id MailId
        , from : Id UserId
        , content : List MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Id MailId) (Id UserId)


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
    , mailDrafts : IdDict UserId (List MailEditor.Content)
    , emailAddress : EmailAddress
    , inbox : IdDict MailId MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }
