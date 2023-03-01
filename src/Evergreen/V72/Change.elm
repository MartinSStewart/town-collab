module Evergreen.V72.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V72.Bounds
import Evergreen.V72.Color
import Evergreen.V72.Coord
import Evergreen.V72.Cursor
import Evergreen.V72.DisplayName
import Evergreen.V72.EmailAddress
import Evergreen.V72.Grid
import Evergreen.V72.GridCell
import Evergreen.V72.Id
import Evergreen.V72.IdDict
import Evergreen.V72.MailEditor
import Evergreen.V72.Point2d
import Evergreen.V72.Train
import Evergreen.V72.Units
import Evergreen.V72.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V72.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V72.Id.Id Evergreen.V72.Id.CowId) (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V72.Id.Id Evergreen.V72.Id.CowId) (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V72.Color.Colors
    | ToggleRailSplit (Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V72.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V72.MailEditor.Content
        , to : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V72.MailEditor.Content
        , to : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V72.Id.Id Evergreen.V72.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V72.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit)


type alias Cow =
    { position : Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit
    }


type alias BackendReport =
    { reportedUser : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V72.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V72.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V72.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId (List Evergreen.V72.MailEditor.Content)
    , emailAddress : Evergreen.V72.EmailAddress.EmailAddress
    , inbox : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.MailId Evergreen.V72.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V72.Grid.GridChange
        , newCells : List (Evergreen.V72.Coord.Coord Evergreen.V72.Units.CellUnit)
        , newCows : List ( Evergreen.V72.Id.Id Evergreen.V72.Id.CowId, Cow )
        }
    | ServerUndoPoint
        { userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V72.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) (Evergreen.V72.Id.Id Evergreen.V72.Id.CowId) (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) (Evergreen.V72.Id.Id Evergreen.V72.Id.CowId) (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , user : Evergreen.V72.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V72.Id.Id Evergreen.V72.Id.CowId, Cow )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V72.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) Evergreen.V72.Color.Colors
    | ServerToggleRailSplit (Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) Evergreen.V72.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , to : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V72.Id.Id Evergreen.V72.Id.MailId) Evergreen.V72.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V72.Id.Id Evergreen.V72.Id.MailId
        , from : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , content : List Evergreen.V72.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V72.Id.Id Evergreen.V72.Id.MailId) (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V72.Id.Id Evergreen.V72.Id.CowId, Cow ))
    | ServerChangeTool (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) Evergreen.V72.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId) (Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V72.Bounds.Bounds Evergreen.V72.Units.CellUnit) (List ( Evergreen.V72.Coord.Coord Evergreen.V72.Units.CellUnit, Evergreen.V72.GridCell.CellData )) (List ( Evergreen.V72.Id.Id Evergreen.V72.Id.CowId, Cow ))


type Change
    = LocalChange (Evergreen.V72.Id.Id Evergreen.V72.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
