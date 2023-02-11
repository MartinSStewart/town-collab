module Evergreen.V60.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V60.Bounds
import Evergreen.V60.Color
import Evergreen.V60.Coord
import Evergreen.V60.Cursor
import Evergreen.V60.DisplayName
import Evergreen.V60.EmailAddress
import Evergreen.V60.Grid
import Evergreen.V60.GridCell
import Evergreen.V60.Id
import Evergreen.V60.IdDict
import Evergreen.V60.MailEditor
import Evergreen.V60.Point2d
import Evergreen.V60.Train
import Evergreen.V60.Units
import Evergreen.V60.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V60.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V60.Id.Id Evergreen.V60.Id.CowId) (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V60.Id.Id Evergreen.V60.Id.CowId) (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V60.Color.Colors
    | ToggleRailSplit (Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V60.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V60.MailEditor.Content
        , to : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V60.MailEditor.Content
        , to : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V60.Id.Id Evergreen.V60.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V60.Cursor.OtherUsersTool
    | AdminResetSessions


type alias Cow =
    { position : Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
            , connectionCount : Int
            }
    }


type alias LoggedIn_ =
    { userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V60.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V60.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V60.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId (List Evergreen.V60.MailEditor.Content)
    , emailAddress : Evergreen.V60.EmailAddress.EmailAddress
    , inbox : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.MailId Evergreen.V60.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V60.Grid.GridChange
        , newCells : List (Evergreen.V60.Coord.Coord Evergreen.V60.Units.CellUnit)
        , newCows : List ( Evergreen.V60.Id.Id Evergreen.V60.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V60.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.CowId) (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.CowId) (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        , user : Evergreen.V60.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V60.Id.Id Evergreen.V60.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V60.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Color.Colors
    | ServerToggleRailSplit (Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        , to : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V60.Id.Id Evergreen.V60.Id.MailId) Evergreen.V60.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V60.Id.Id Evergreen.V60.Id.MailId
        , from : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        , content : List Evergreen.V60.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V60.Id.Id Evergreen.V60.Id.MailId) (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V60.Id.Id Evergreen.V60.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) Evergreen.V60.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V60.Bounds.Bounds Evergreen.V60.Units.CellUnit) (List ( Evergreen.V60.Coord.Coord Evergreen.V60.Units.CellUnit, Evergreen.V60.GridCell.CellData )) (List ( Evergreen.V60.Id.Id Evergreen.V60.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V60.Id.Id Evergreen.V60.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
