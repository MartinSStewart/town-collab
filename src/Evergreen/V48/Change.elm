module Evergreen.V48.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V48.Bounds
import Evergreen.V48.Color
import Evergreen.V48.Coord
import Evergreen.V48.DisplayName
import Evergreen.V48.EmailAddress
import Evergreen.V48.Grid
import Evergreen.V48.GridCell
import Evergreen.V48.Id
import Evergreen.V48.IdDict
import Evergreen.V48.MailEditor
import Evergreen.V48.Point2d
import Evergreen.V48.Train
import Evergreen.V48.Units
import Evergreen.V48.User


type LocalChange
    = LocalGridChange Evergreen.V48.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V48.Id.Id Evergreen.V48.Id.CowId) (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V48.Id.Id Evergreen.V48.Id.CowId) (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V48.Color.Colors
    | ToggleRailSplit (Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V48.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V48.MailEditor.Content
        , to : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V48.MailEditor.Content
        , to : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V48.Id.Id Evergreen.V48.Id.MailId)


type alias LoggedIn_ =
    { userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V48.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V48.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V48.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId (List Evergreen.V48.MailEditor.Content)
    , emailAddress : Evergreen.V48.EmailAddress.EmailAddress
    , inbox : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.MailId Evergreen.V48.MailEditor.ReceivedMail
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V48.Grid.GridChange
        , newCells : List (Evergreen.V48.Coord.Coord Evergreen.V48.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V48.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Evergreen.V48.Id.Id Evergreen.V48.Id.CowId) (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Evergreen.V48.Id.Id Evergreen.V48.Id.CowId) (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)
    | ServerUserConnected (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.User.FrontendUser
    | ServerYouLoggedIn LoggedIn_ Evergreen.V48.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.Color.Colors
    | ServerToggleRailSplit (Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        , to : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V48.Id.Id Evergreen.V48.Id.MailId) Evergreen.V48.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V48.Id.Id Evergreen.V48.Id.MailId
        , from : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        , content : List Evergreen.V48.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V48.Id.Id Evergreen.V48.Id.MailId) (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V48.Bounds.Bounds Evergreen.V48.Units.CellUnit) (List ( Evergreen.V48.Coord.Coord Evergreen.V48.Units.CellUnit, Evergreen.V48.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V48.Id.Id Evergreen.V48.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit
    }
