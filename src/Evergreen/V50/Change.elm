module Evergreen.V50.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V50.Bounds
import Evergreen.V50.Color
import Evergreen.V50.Coord
import Evergreen.V50.DisplayName
import Evergreen.V50.EmailAddress
import Evergreen.V50.Grid
import Evergreen.V50.GridCell
import Evergreen.V50.Id
import Evergreen.V50.IdDict
import Evergreen.V50.MailEditor
import Evergreen.V50.Point2d
import Evergreen.V50.Train
import Evergreen.V50.Units
import Evergreen.V50.User


type LocalChange
    = LocalGridChange Evergreen.V50.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V50.Id.Id Evergreen.V50.Id.CowId) (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V50.Id.Id Evergreen.V50.Id.CowId) (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V50.Color.Colors
    | ToggleRailSplit (Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V50.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V50.MailEditor.Content
        , to : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V50.MailEditor.Content
        , to : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V50.Id.Id Evergreen.V50.Id.MailId)
    | SetAllowEmailNotifications Bool


type alias LoggedIn_ =
    { userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V50.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V50.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V50.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId (List Evergreen.V50.MailEditor.Content)
    , emailAddress : Evergreen.V50.EmailAddress.EmailAddress
    , inbox : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.MailId Evergreen.V50.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V50.Grid.GridChange
        , newCells : List (Evergreen.V50.Coord.Coord Evergreen.V50.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V50.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Id.Id Evergreen.V50.Id.CowId) (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Id.Id Evergreen.V50.Id.CowId) (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)
    | ServerUserConnected (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.User.FrontendUser
    | ServerYouLoggedIn LoggedIn_ Evergreen.V50.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.Color.Colors
    | ServerToggleRailSplit (Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        , to : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V50.Id.Id Evergreen.V50.Id.MailId) Evergreen.V50.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V50.Id.Id Evergreen.V50.Id.MailId
        , from : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        , content : List Evergreen.V50.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V50.Id.Id Evergreen.V50.Id.MailId) (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V50.Bounds.Bounds Evergreen.V50.Units.CellUnit) (List ( Evergreen.V50.Coord.Coord Evergreen.V50.Units.CellUnit, Evergreen.V50.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V50.Id.Id Evergreen.V50.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit
    }
