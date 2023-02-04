module Evergreen.V56.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V56.Bounds
import Evergreen.V56.Color
import Evergreen.V56.Coord
import Evergreen.V56.DisplayName
import Evergreen.V56.EmailAddress
import Evergreen.V56.Grid
import Evergreen.V56.GridCell
import Evergreen.V56.Id
import Evergreen.V56.IdDict
import Evergreen.V56.MailEditor
import Evergreen.V56.Point2d
import Evergreen.V56.Train
import Evergreen.V56.Units
import Evergreen.V56.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V56.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V56.Id.Id Evergreen.V56.Id.CowId) (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V56.Id.Id Evergreen.V56.Id.CowId) (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V56.Color.Colors
    | ToggleRailSplit (Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V56.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V56.MailEditor.Content
        , to : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V56.MailEditor.Content
        , to : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V56.Id.Id Evergreen.V56.Id.MailId)
    | SetAllowEmailNotifications Bool


type alias Cow =
    { position : Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit
    }


type alias LoggedIn_ =
    { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V56.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V56.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V56.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId (List Evergreen.V56.MailEditor.Content)
    , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
    , inbox : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.MailId Evergreen.V56.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V56.Grid.GridChange
        , newCells : List (Evergreen.V56.Coord.Coord Evergreen.V56.Units.CellUnit)
        , newCows : List ( Evergreen.V56.Id.Id Evergreen.V56.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V56.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.CowId) (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.CowId) (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , user : Evergreen.V56.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V56.Id.Id Evergreen.V56.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V56.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Color.Colors
    | ServerToggleRailSplit (Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , to : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V56.Id.Id Evergreen.V56.Id.MailId) Evergreen.V56.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V56.Id.Id Evergreen.V56.Id.MailId
        , from : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , content : List Evergreen.V56.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V56.Id.Id Evergreen.V56.Id.MailId) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V56.Id.Id Evergreen.V56.Id.CowId, Cow ))


type ClientChange
    = ViewBoundsChange (Evergreen.V56.Bounds.Bounds Evergreen.V56.Units.CellUnit) (List ( Evergreen.V56.Coord.Coord Evergreen.V56.Units.CellUnit, Evergreen.V56.GridCell.CellData )) (List ( Evergreen.V56.Id.Id Evergreen.V56.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V56.Id.Id Evergreen.V56.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
