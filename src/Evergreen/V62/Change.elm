module Evergreen.V62.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V62.Bounds
import Evergreen.V62.Color
import Evergreen.V62.Coord
import Evergreen.V62.Cursor
import Evergreen.V62.DisplayName
import Evergreen.V62.EmailAddress
import Evergreen.V62.Grid
import Evergreen.V62.GridCell
import Evergreen.V62.Id
import Evergreen.V62.IdDict
import Evergreen.V62.MailEditor
import Evergreen.V62.Point2d
import Evergreen.V62.Train
import Evergreen.V62.Units
import Evergreen.V62.User
import List.Nonempty


type LocalChange
    = LocalGridChange Evergreen.V62.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V62.Id.Id Evergreen.V62.Id.CowId) (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V62.Id.Id Evergreen.V62.Id.CowId) (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V62.Color.Colors
    | ToggleRailSplit (Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V62.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V62.MailEditor.Content
        , to : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V62.MailEditor.Content
        , to : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V62.Id.Id Evergreen.V62.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V62.Cursor.OtherUsersTool
    | AdminResetSessions


type alias Cow =
    { position : Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
            , connectionCount : Int
            }
    }


type alias LoggedIn_ =
    { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V62.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V62.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V62.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId (List Evergreen.V62.MailEditor.Content)
    , emailAddress : Evergreen.V62.EmailAddress.EmailAddress
    , inbox : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.MailId Evergreen.V62.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V62.Grid.GridChange
        , newCells : List (Evergreen.V62.Coord.Coord Evergreen.V62.Units.CellUnit)
        , newCows : List ( Evergreen.V62.Id.Id Evergreen.V62.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V62.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Id.Id Evergreen.V62.Id.CowId) (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Id.Id Evergreen.V62.Id.CowId) (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        , user : Evergreen.V62.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V62.Id.Id Evergreen.V62.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V62.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.Color.Colors
    | ServerToggleRailSplit (Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        , to : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V62.Id.Id Evergreen.V62.Id.MailId) Evergreen.V62.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V62.Id.Id Evergreen.V62.Id.MailId
        , from : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        , content : List Evergreen.V62.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V62.Id.Id Evergreen.V62.Id.MailId) (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V62.Id.Id Evergreen.V62.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V62.Bounds.Bounds Evergreen.V62.Units.CellUnit) (List ( Evergreen.V62.Coord.Coord Evergreen.V62.Units.CellUnit, Evergreen.V62.GridCell.CellData )) (List ( Evergreen.V62.Id.Id Evergreen.V62.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V62.Id.Id Evergreen.V62.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
