module Evergreen.V77.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V77.Animal
import Evergreen.V77.Bounds
import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.Cursor
import Evergreen.V77.DisplayName
import Evergreen.V77.EmailAddress
import Evergreen.V77.Grid
import Evergreen.V77.GridCell
import Evergreen.V77.Id
import Evergreen.V77.IdDict
import Evergreen.V77.MailEditor
import Evergreen.V77.Point2d
import Evergreen.V77.Train
import Evergreen.V77.Units
import Evergreen.V77.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V77.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId) (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId) (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V77.Color.Colors
    | ToggleRailSplit (Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V77.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V77.MailEditor.Content
        , to : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V77.MailEditor.Content
        , to : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V77.Id.Id Evergreen.V77.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V77.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V77.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V77.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V77.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId (List Evergreen.V77.MailEditor.Content)
    , emailAddress : Evergreen.V77.EmailAddress.EmailAddress
    , inbox : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.MailId Evergreen.V77.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V77.Grid.GridChange
        , newCells : List (Evergreen.V77.Coord.Coord Evergreen.V77.Units.CellUnit)
        , newCows : List ( Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId, Evergreen.V77.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V77.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId) (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId) (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , user : Evergreen.V77.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId, Evergreen.V77.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V77.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Color.Colors
    | ServerToggleRailSplit (Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , to : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V77.Id.Id Evergreen.V77.Id.MailId) Evergreen.V77.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V77.Id.Id Evergreen.V77.Id.MailId
        , from : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , content : List Evergreen.V77.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V77.Id.Id Evergreen.V77.Id.MailId) (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId, Evergreen.V77.Animal.Animal ))
    | ServerChangeTool (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) Evergreen.V77.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V77.Bounds.Bounds Evergreen.V77.Units.CellUnit) (List ( Evergreen.V77.Coord.Coord Evergreen.V77.Units.CellUnit, Evergreen.V77.GridCell.CellData )) (List ( Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId, Evergreen.V77.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V77.Id.Id Evergreen.V77.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
