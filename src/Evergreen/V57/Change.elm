module Evergreen.V57.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V57.Bounds
import Evergreen.V57.Color
import Evergreen.V57.Coord
import Evergreen.V57.Cursor
import Evergreen.V57.DisplayName
import Evergreen.V57.EmailAddress
import Evergreen.V57.Grid
import Evergreen.V57.GridCell
import Evergreen.V57.Id
import Evergreen.V57.IdDict
import Evergreen.V57.MailEditor
import Evergreen.V57.Point2d
import Evergreen.V57.Train
import Evergreen.V57.Units
import Evergreen.V57.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V57.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V57.Id.Id Evergreen.V57.Id.CowId) (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V57.Id.Id Evergreen.V57.Id.CowId) (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V57.Color.Colors
    | ToggleRailSplit (Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V57.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V57.MailEditor.Content
        , to : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V57.MailEditor.Content
        , to : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V57.Id.Id Evergreen.V57.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V57.Cursor.OtherUsersTool


type alias Cow =
    { position : Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit
    }


type alias LoggedIn_ =
    { userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V57.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V57.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V57.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId (List Evergreen.V57.MailEditor.Content)
    , emailAddress : Evergreen.V57.EmailAddress.EmailAddress
    , inbox : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.MailId Evergreen.V57.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V57.Grid.GridChange
        , newCells : List (Evergreen.V57.Coord.Coord Evergreen.V57.Units.CellUnit)
        , newCows : List ( Evergreen.V57.Id.Id Evergreen.V57.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V57.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId) (Evergreen.V57.Id.Id Evergreen.V57.Id.CowId) (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId) (Evergreen.V57.Id.Id Evergreen.V57.Id.CowId) (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId) (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        , user : Evergreen.V57.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V57.Id.Id Evergreen.V57.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V57.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId) Evergreen.V57.Color.Colors
    | ServerToggleRailSplit (Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId) Evergreen.V57.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        , to : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V57.Id.Id Evergreen.V57.Id.MailId) Evergreen.V57.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V57.Id.Id Evergreen.V57.Id.MailId
        , from : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        , content : List Evergreen.V57.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V57.Id.Id Evergreen.V57.Id.MailId) (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V57.Id.Id Evergreen.V57.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId) Evergreen.V57.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V57.Bounds.Bounds Evergreen.V57.Units.CellUnit) (List ( Evergreen.V57.Coord.Coord Evergreen.V57.Units.CellUnit, Evergreen.V57.GridCell.CellData )) (List ( Evergreen.V57.Id.Id Evergreen.V57.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V57.Id.Id Evergreen.V57.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
