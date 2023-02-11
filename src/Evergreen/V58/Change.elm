module Evergreen.V58.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V58.Bounds
import Evergreen.V58.Color
import Evergreen.V58.Coord
import Evergreen.V58.Cursor
import Evergreen.V58.DisplayName
import Evergreen.V58.EmailAddress
import Evergreen.V58.Grid
import Evergreen.V58.GridCell
import Evergreen.V58.Id
import Evergreen.V58.IdDict
import Evergreen.V58.MailEditor
import Evergreen.V58.Point2d
import Evergreen.V58.Train
import Evergreen.V58.Units
import Evergreen.V58.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V58.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V58.Id.Id Evergreen.V58.Id.CowId) (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V58.Id.Id Evergreen.V58.Id.CowId) (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V58.Color.Colors
    | ToggleRailSplit (Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V58.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V58.MailEditor.Content
        , to : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V58.MailEditor.Content
        , to : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V58.Id.Id Evergreen.V58.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V58.Cursor.OtherUsersTool


type alias Cow =
    { position : Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit
    }


type alias LoggedIn_ =
    { userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V58.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V58.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V58.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId (List Evergreen.V58.MailEditor.Content)
    , emailAddress : Evergreen.V58.EmailAddress.EmailAddress
    , inbox : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.MailId Evergreen.V58.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V58.Grid.GridChange
        , newCells : List (Evergreen.V58.Coord.Coord Evergreen.V58.Units.CellUnit)
        , newCows : List ( Evergreen.V58.Id.Id Evergreen.V58.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V58.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId) (Evergreen.V58.Id.Id Evergreen.V58.Id.CowId) (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId) (Evergreen.V58.Id.Id Evergreen.V58.Id.CowId) (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId) (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        , user : Evergreen.V58.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V58.Id.Id Evergreen.V58.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V58.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId) Evergreen.V58.Color.Colors
    | ServerToggleRailSplit (Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId) Evergreen.V58.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        , to : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V58.Id.Id Evergreen.V58.Id.MailId) Evergreen.V58.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V58.Id.Id Evergreen.V58.Id.MailId
        , from : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        , content : List Evergreen.V58.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V58.Id.Id Evergreen.V58.Id.MailId) (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V58.Id.Id Evergreen.V58.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId) Evergreen.V58.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V58.Bounds.Bounds Evergreen.V58.Units.CellUnit) (List ( Evergreen.V58.Coord.Coord Evergreen.V58.Units.CellUnit, Evergreen.V58.GridCell.CellData )) (List ( Evergreen.V58.Id.Id Evergreen.V58.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V58.Id.Id Evergreen.V58.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
