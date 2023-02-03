module Evergreen.V47.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V47.Bounds
import Evergreen.V47.Color
import Evergreen.V47.Coord
import Evergreen.V47.DisplayName
import Evergreen.V47.EmailAddress
import Evergreen.V47.Grid
import Evergreen.V47.GridCell
import Evergreen.V47.Id
import Evergreen.V47.IdDict
import Evergreen.V47.MailEditor
import Evergreen.V47.Point2d
import Evergreen.V47.Train
import Evergreen.V47.Units
import Evergreen.V47.User


type LocalChange
    = LocalGridChange Evergreen.V47.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V47.Id.Id Evergreen.V47.Id.CowId) (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V47.Id.Id Evergreen.V47.Id.CowId) (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V47.Color.Colors
    | ToggleRailSplit (Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V47.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V47.MailEditor.Content
        , to : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V47.MailEditor.Content
        , to : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V47.Id.Id Evergreen.V47.Id.MailId)


type alias LoggedIn_ =
    { userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V47.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V47.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V47.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId (List Evergreen.V47.MailEditor.Content)
    , emailAddress : Evergreen.V47.EmailAddress.EmailAddress
    , inbox : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.MailId Evergreen.V47.MailEditor.ReceivedMail
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V47.Grid.GridChange
        , newCells : List (Evergreen.V47.Coord.Coord Evergreen.V47.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V47.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId) (Evergreen.V47.Id.Id Evergreen.V47.Id.CowId) (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId) (Evergreen.V47.Id.Id Evergreen.V47.Id.CowId) (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId) (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId)
    | ServerUserConnected (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId) Evergreen.V47.User.FrontendUser
    | ServerYouLoggedIn LoggedIn_ Evergreen.V47.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId) Evergreen.V47.Color.Colors
    | ServerToggleRailSplit (Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId) Evergreen.V47.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        , to : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V47.Id.Id Evergreen.V47.Id.MailId) Evergreen.V47.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V47.Id.Id Evergreen.V47.Id.MailId
        , from : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        , content : List Evergreen.V47.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V47.Id.Id Evergreen.V47.Id.MailId) (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V47.Bounds.Bounds Evergreen.V47.Units.CellUnit) (List ( Evergreen.V47.Coord.Coord Evergreen.V47.Units.CellUnit, Evergreen.V47.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V47.Id.Id Evergreen.V47.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit
    }
