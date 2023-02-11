module Evergreen.V59.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V59.Bounds
import Evergreen.V59.Color
import Evergreen.V59.Coord
import Evergreen.V59.Cursor
import Evergreen.V59.DisplayName
import Evergreen.V59.EmailAddress
import Evergreen.V59.Grid
import Evergreen.V59.GridCell
import Evergreen.V59.Id
import Evergreen.V59.IdDict
import Evergreen.V59.MailEditor
import Evergreen.V59.Point2d
import Evergreen.V59.Train
import Evergreen.V59.Units
import Evergreen.V59.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V59.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V59.Id.Id Evergreen.V59.Id.CowId) (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V59.Id.Id Evergreen.V59.Id.CowId) (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V59.Color.Colors
    | ToggleRailSplit (Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V59.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V59.MailEditor.Content
        , to : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V59.MailEditor.Content
        , to : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V59.Id.Id Evergreen.V59.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V59.Cursor.OtherUsersTool
    | AdminResetSessions


type alias Cow =
    { position : Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
            , connectionCount : Int
            }
    }


type alias LoggedIn_ =
    { userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V59.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V59.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V59.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId (List Evergreen.V59.MailEditor.Content)
    , emailAddress : Evergreen.V59.EmailAddress.EmailAddress
    , inbox : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.MailId Evergreen.V59.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V59.Grid.GridChange
        , newCells : List (Evergreen.V59.Coord.Coord Evergreen.V59.Units.CellUnit)
        , newCows : List ( Evergreen.V59.Id.Id Evergreen.V59.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V59.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.CowId) (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.CowId) (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        , user : Evergreen.V59.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V59.Id.Id Evergreen.V59.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V59.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Color.Colors
    | ServerToggleRailSplit (Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        , to : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V59.Id.Id Evergreen.V59.Id.MailId) Evergreen.V59.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V59.Id.Id Evergreen.V59.Id.MailId
        , from : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        , content : List Evergreen.V59.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V59.Id.Id Evergreen.V59.Id.MailId) (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V59.Id.Id Evergreen.V59.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V59.Bounds.Bounds Evergreen.V59.Units.CellUnit) (List ( Evergreen.V59.Coord.Coord Evergreen.V59.Units.CellUnit, Evergreen.V59.GridCell.CellData )) (List ( Evergreen.V59.Id.Id Evergreen.V59.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V59.Id.Id Evergreen.V59.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
