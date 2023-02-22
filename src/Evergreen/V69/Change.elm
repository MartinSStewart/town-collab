module Evergreen.V69.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V69.Bounds
import Evergreen.V69.Color
import Evergreen.V69.Coord
import Evergreen.V69.Cursor
import Evergreen.V69.DisplayName
import Evergreen.V69.EmailAddress
import Evergreen.V69.Grid
import Evergreen.V69.GridCell
import Evergreen.V69.Id
import Evergreen.V69.IdDict
import Evergreen.V69.MailEditor
import Evergreen.V69.Point2d
import Evergreen.V69.Train
import Evergreen.V69.Units
import Evergreen.V69.User
import List.Nonempty


type alias Report =
    { reportedUser : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V69.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V69.Id.Id Evergreen.V69.Id.CowId) (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V69.Id.Id Evergreen.V69.Id.CowId) (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V69.Color.Colors
    | ToggleRailSplit (Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V69.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V69.MailEditor.Content
        , to : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V69.MailEditor.Content
        , to : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V69.Id.Id Evergreen.V69.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V69.Cursor.OtherUsersTool
    | AdminResetSessions
    | ReportVandalism Report
    | RemoveReport (Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit)


type alias Cow =
    { position : Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
            , connectionCount : Int
            }
    }


type alias LoggedIn_ =
    { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V69.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V69.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V69.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId (List Evergreen.V69.MailEditor.Content)
    , emailAddress : Evergreen.V69.EmailAddress.EmailAddress
    , inbox : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.MailId Evergreen.V69.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V69.Grid.GridChange
        , newCells : List (Evergreen.V69.Coord.Coord Evergreen.V69.Units.CellUnit)
        , newCows : List ( Evergreen.V69.Id.Id Evergreen.V69.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V69.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Id.Id Evergreen.V69.Id.CowId) (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Id.Id Evergreen.V69.Id.CowId) (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , user : Evergreen.V69.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V69.Id.Id Evergreen.V69.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V69.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.Color.Colors
    | ServerToggleRailSplit (Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , to : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V69.Id.Id Evergreen.V69.Id.MailId) Evergreen.V69.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V69.Id.Id Evergreen.V69.Id.MailId
        , from : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , content : List Evergreen.V69.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V69.Id.Id Evergreen.V69.Id.MailId) (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V69.Id.Id Evergreen.V69.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.Cursor.OtherUsersTool


type ClientChange
    = ViewBoundsChange (Evergreen.V69.Bounds.Bounds Evergreen.V69.Units.CellUnit) (List ( Evergreen.V69.Coord.Coord Evergreen.V69.Units.CellUnit, Evergreen.V69.GridCell.CellData )) (List ( Evergreen.V69.Id.Id Evergreen.V69.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V69.Id.Id Evergreen.V69.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
