module Evergreen.V52.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V52.Bounds
import Evergreen.V52.Color
import Evergreen.V52.Coord
import Evergreen.V52.DisplayName
import Evergreen.V52.EmailAddress
import Evergreen.V52.Grid
import Evergreen.V52.GridCell
import Evergreen.V52.Id
import Evergreen.V52.IdDict
import Evergreen.V52.MailEditor
import Evergreen.V52.Point2d
import Evergreen.V52.Train
import Evergreen.V52.Units
import Evergreen.V52.User


type LocalChange
    = LocalGridChange Evergreen.V52.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V52.Id.Id Evergreen.V52.Id.CowId) (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V52.Id.Id Evergreen.V52.Id.CowId) (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V52.Color.Colors
    | ToggleRailSplit (Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V52.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V52.MailEditor.Content
        , to : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V52.MailEditor.Content
        , to : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V52.Id.Id Evergreen.V52.Id.MailId)
    | SetAllowEmailNotifications Bool


type alias LoggedIn_ =
    { userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V52.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V52.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V52.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId (List Evergreen.V52.MailEditor.Content)
    , emailAddress : Evergreen.V52.EmailAddress.EmailAddress
    , inbox : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.MailId Evergreen.V52.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V52.Grid.GridChange
        , newCells : List (Evergreen.V52.Coord.Coord Evergreen.V52.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V52.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.CowId) (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.CowId) (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
    | ServerUserConnected (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.User.FrontendUser
    | ServerYouLoggedIn LoggedIn_ Evergreen.V52.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Color.Colors
    | ServerToggleRailSplit (Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        , to : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V52.Id.Id Evergreen.V52.Id.MailId) Evergreen.V52.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V52.Id.Id Evergreen.V52.Id.MailId
        , from : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        , content : List Evergreen.V52.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V52.Id.Id Evergreen.V52.Id.MailId) (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V52.Bounds.Bounds Evergreen.V52.Units.CellUnit) (List ( Evergreen.V52.Coord.Coord Evergreen.V52.Units.CellUnit, Evergreen.V52.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V52.Id.Id Evergreen.V52.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit
    }
