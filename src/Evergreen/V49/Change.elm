module Evergreen.V49.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V49.Bounds
import Evergreen.V49.Color
import Evergreen.V49.Coord
import Evergreen.V49.DisplayName
import Evergreen.V49.EmailAddress
import Evergreen.V49.Grid
import Evergreen.V49.GridCell
import Evergreen.V49.Id
import Evergreen.V49.IdDict
import Evergreen.V49.MailEditor
import Evergreen.V49.Point2d
import Evergreen.V49.Train
import Evergreen.V49.Units
import Evergreen.V49.User


type LocalChange
    = LocalGridChange Evergreen.V49.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V49.Id.Id Evergreen.V49.Id.CowId) (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V49.Id.Id Evergreen.V49.Id.CowId) (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V49.Color.Colors
    | ToggleRailSplit (Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V49.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V49.MailEditor.Content
        , to : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V49.MailEditor.Content
        , to : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V49.Id.Id Evergreen.V49.Id.MailId)


type alias LoggedIn_ =
    { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V49.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V49.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V49.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId (List Evergreen.V49.MailEditor.Content)
    , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
    , inbox : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.MailId Evergreen.V49.MailEditor.ReceivedMail
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V49.Grid.GridChange
        , newCells : List (Evergreen.V49.Coord.Coord Evergreen.V49.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V49.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.CowId) (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.CowId) (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | ServerUserConnected (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.User.FrontendUser
    | ServerYouLoggedIn LoggedIn_ Evergreen.V49.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Color.Colors
    | ServerToggleRailSplit (Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        , to : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V49.Id.Id Evergreen.V49.Id.MailId) Evergreen.V49.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V49.Id.Id Evergreen.V49.Id.MailId
        , from : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        , content : List Evergreen.V49.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V49.Id.Id Evergreen.V49.Id.MailId) (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V49.Bounds.Bounds Evergreen.V49.Units.CellUnit) (List ( Evergreen.V49.Coord.Coord Evergreen.V49.Units.CellUnit, Evergreen.V49.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V49.Id.Id Evergreen.V49.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit
    }
