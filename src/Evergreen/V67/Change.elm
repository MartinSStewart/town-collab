module Evergreen.V67.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V67.Bounds
import Evergreen.V67.Color
import Evergreen.V67.Coord
import Evergreen.V67.Cursor
import Evergreen.V67.DisplayName
import Evergreen.V67.EmailAddress
import Evergreen.V67.Grid
import Evergreen.V67.GridCell
import Evergreen.V67.Id
import Evergreen.V67.IdDict
import Evergreen.V67.MailEditor
import Evergreen.V67.Point2d
import Evergreen.V67.Train
import Evergreen.V67.Units
import Evergreen.V67.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V67.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V67.Id.Id Evergreen.V67.Id.CowId) (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V67.Id.Id Evergreen.V67.Id.CowId) (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V67.Color.Colors
    | ToggleRailSplit (Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V67.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V67.MailEditor.Content
        , to : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V67.MailEditor.Content
        , to : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V67.Id.Id Evergreen.V67.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V67.Cursor.OtherUsersTool
    | AdminResetSessions


type alias Cow =
    { position : Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId)
            , connectionCount : Int
            }
    }


type alias LoggedIn_ =
    { userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V67.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V67.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V67.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId (List Evergreen.V67.MailEditor.Content)
    , emailAddress : Evergreen.V67.EmailAddress.EmailAddress
    , inbox : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.MailId Evergreen.V67.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V67.Grid.GridChange
        , newCells : List (Evergreen.V67.Coord.Coord Evergreen.V67.Units.CellUnit)
        , newCows : List ( Evergreen.V67.Id.Id Evergreen.V67.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V67.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId) (Evergreen.V67.Id.Id Evergreen.V67.Id.CowId) (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId) (Evergreen.V67.Id.Id Evergreen.V67.Id.CowId) (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId) (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        , user : Evergreen.V67.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V67.Id.Id Evergreen.V67.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V67.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId) Evergreen.V67.Color.Colors
    | ServerToggleRailSplit (Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId) Evergreen.V67.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        , to : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V67.Id.Id Evergreen.V67.Id.MailId) Evergreen.V67.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V67.Id.Id Evergreen.V67.Id.MailId
        , from : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        , content : List Evergreen.V67.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V67.Id.Id Evergreen.V67.Id.MailId) (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V67.Id.Id Evergreen.V67.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId) Evergreen.V67.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V67.Bounds.Bounds Evergreen.V67.Units.CellUnit) (List ( Evergreen.V67.Coord.Coord Evergreen.V67.Units.CellUnit, Evergreen.V67.GridCell.CellData )) (List ( Evergreen.V67.Id.Id Evergreen.V67.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V67.Id.Id Evergreen.V67.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
