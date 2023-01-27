module Evergreen.V46.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V46.Bounds
import Evergreen.V46.Color
import Evergreen.V46.Coord
import Evergreen.V46.DisplayName
import Evergreen.V46.EmailAddress
import Evergreen.V46.Grid
import Evergreen.V46.GridCell
import Evergreen.V46.Id
import Evergreen.V46.IdDict
import Evergreen.V46.MailEditor
import Evergreen.V46.Point2d
import Evergreen.V46.Train
import Evergreen.V46.Units
import Evergreen.V46.User


type LocalChange
    = LocalGridChange Evergreen.V46.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V46.Id.Id Evergreen.V46.Id.CowId) (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V46.Id.Id Evergreen.V46.Id.CowId) (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V46.Color.Colors
    | ToggleRailSplit (Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V46.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V46.MailEditor.Content
        , to : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V46.MailEditor.Content
        , to : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V46.Id.Id Evergreen.V46.Id.MailId)


type alias LoggedIn_ =
    { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V46.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V46.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V46.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId (List Evergreen.V46.MailEditor.Content)
    , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
    , inbox : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.MailId Evergreen.V46.MailEditor.ReceivedMail
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V46.Grid.GridChange
        , newCells : List (Evergreen.V46.Coord.Coord Evergreen.V46.Units.CellUnit)
        }
    | ServerUndoPoint
        { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V46.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.CowId) (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.CowId) (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | ServerUserConnected (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.User.FrontendUser
    | ServerYouLoggedIn LoggedIn_ Evergreen.V46.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Color.Colors
    | ServerToggleRailSplit (Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        , to : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V46.Id.Id Evergreen.V46.Id.MailId) Evergreen.V46.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V46.Id.Id Evergreen.V46.Id.MailId
        , from : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        , content : List Evergreen.V46.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V46.Id.Id Evergreen.V46.Id.MailId) (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)


type ClientChange
    = ViewBoundsChange (Evergreen.V46.Bounds.Bounds Evergreen.V46.Units.CellUnit) (List ( Evergreen.V46.Coord.Coord Evergreen.V46.Units.CellUnit, Evergreen.V46.GridCell.CellData ))


type Change
    = LocalChange (Evergreen.V46.Id.Id Evergreen.V46.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn


type alias Cow =
    { position : Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit
    }
