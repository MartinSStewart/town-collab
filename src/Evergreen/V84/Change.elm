module Evergreen.V84.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V84.Animal
import Evergreen.V84.Bounds
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.Cursor
import Evergreen.V84.DisplayName
import Evergreen.V84.EmailAddress
import Evergreen.V84.Grid
import Evergreen.V84.GridCell
import Evergreen.V84.Id
import Evergreen.V84.IdDict
import Evergreen.V84.MailEditor
import Evergreen.V84.Point2d
import Evergreen.V84.Train
import Evergreen.V84.Units
import Evergreen.V84.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V84.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId) (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId) (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V84.Color.Colors
    | ToggleRailSplit (Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V84.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V84.MailEditor.Content
        , to : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V84.MailEditor.Content
        , to : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V84.Id.Id Evergreen.V84.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V84.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V84.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V84.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V84.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId (List Evergreen.V84.MailEditor.Content)
    , emailAddress : Evergreen.V84.EmailAddress.EmailAddress
    , inbox : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.MailId Evergreen.V84.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V84.Grid.GridChange
        , newCells : List (Evergreen.V84.Coord.Coord Evergreen.V84.Units.CellUnit)
        , newCows : List ( Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId, Evergreen.V84.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V84.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) (Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId) (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) (Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId) (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , user : Evergreen.V84.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId, Evergreen.V84.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V84.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) Evergreen.V84.Color.Colors
    | ServerToggleRailSplit (Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) Evergreen.V84.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , to : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V84.Id.Id Evergreen.V84.Id.MailId) Evergreen.V84.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V84.Id.Id Evergreen.V84.Id.MailId
        , from : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , content : List Evergreen.V84.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V84.Id.Id Evergreen.V84.Id.MailId) (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId, Evergreen.V84.Animal.Animal ))
    | ServerChangeTool (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) Evergreen.V84.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId) (Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V84.Bounds.Bounds Evergreen.V84.Units.CellUnit) (List ( Evergreen.V84.Coord.Coord Evergreen.V84.Units.CellUnit, Evergreen.V84.GridCell.CellData )) (List ( Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId, Evergreen.V84.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V84.Id.Id Evergreen.V84.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
