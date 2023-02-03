module Evergreen.V54.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V54.Bounds
import Evergreen.V54.Color
import Evergreen.V54.Coord
import Evergreen.V54.DisplayName
import Evergreen.V54.EmailAddress
import Evergreen.V54.Grid
import Evergreen.V54.GridCell
import Evergreen.V54.Id
import Evergreen.V54.IdDict
import Evergreen.V54.MailEditor
import Evergreen.V54.Point2d
import Evergreen.V54.Train
import Evergreen.V54.Units
import Evergreen.V54.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V54.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V54.Id.Id Evergreen.V54.Id.CowId) (Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V54.Id.Id Evergreen.V54.Id.CowId) (Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V54.Color.Colors
    | ToggleRailSplit (Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V54.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V54.MailEditor.Content
        , to : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V54.MailEditor.Content
        , to : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V54.Id.Id Evergreen.V54.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V54.Id.Id Evergreen.V54.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V54.Id.Id Evergreen.V54.Id.MailId)
    | SetAllowEmailNotifications Bool


type alias Cow =
    { position : Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit
    }


type alias LoggedIn_ =
    { userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V54.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V54.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V54.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.UserId (List Evergreen.V54.MailEditor.Content)
    , emailAddress : Evergreen.V54.EmailAddress.EmailAddress
    , inbox : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.MailId Evergreen.V54.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }


type ServerChange
    = ServerUndoPoint
        { userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V54.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.CowId) (Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.CowId) (Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        , user : Evergreen.V54.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V54.Id.Id Evergreen.V54.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V54.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.Color.Colors
    | ServerToggleRailSplit (Evergreen.V54.Coord.Coord Evergreen.V54.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) Evergreen.V54.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        , to : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V54.Id.Id Evergreen.V54.Id.MailId) Evergreen.V54.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V54.Id.Id Evergreen.V54.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V54.Id.Id Evergreen.V54.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.TrainId Evergreen.V54.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V54.Id.Id Evergreen.V54.Id.MailId
        , from : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
        , content : List Evergreen.V54.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V54.Id.Id Evergreen.V54.Id.MailId) (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V54.Id.Id Evergreen.V54.Id.CowId, Cow ))


type ClientChange
    = ViewBoundsChange (Evergreen.V54.Bounds.Bounds Evergreen.V54.Units.CellUnit) (List ( Evergreen.V54.Coord.Coord Evergreen.V54.Units.CellUnit, Evergreen.V54.GridCell.CellData )) (List ( Evergreen.V54.Id.Id Evergreen.V54.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V54.Id.Id Evergreen.V54.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
