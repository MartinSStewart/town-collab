module Evergreen.V82.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V82.Animal
import Evergreen.V82.Bounds
import Evergreen.V82.Color
import Evergreen.V82.Coord
import Evergreen.V82.Cursor
import Evergreen.V82.DisplayName
import Evergreen.V82.EmailAddress
import Evergreen.V82.Grid
import Evergreen.V82.GridCell
import Evergreen.V82.Id
import Evergreen.V82.IdDict
import Evergreen.V82.MailEditor
import Evergreen.V82.Point2d
import Evergreen.V82.Train
import Evergreen.V82.Units
import Evergreen.V82.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V82.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId) (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId) (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V82.Color.Colors
    | ToggleRailSplit (Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V82.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V82.MailEditor.Content
        , to : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V82.MailEditor.Content
        , to : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V82.Id.Id Evergreen.V82.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V82.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V82.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V82.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V82.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId (List Evergreen.V82.MailEditor.Content)
    , emailAddress : Evergreen.V82.EmailAddress.EmailAddress
    , inbox : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.MailId Evergreen.V82.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V82.Grid.GridChange
        , newCells : List (Evergreen.V82.Coord.Coord Evergreen.V82.Units.CellUnit)
        , newCows : List ( Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId, Evergreen.V82.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V82.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) (Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId) (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) (Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId) (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , user : Evergreen.V82.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId, Evergreen.V82.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V82.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) Evergreen.V82.Color.Colors
    | ServerToggleRailSplit (Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) Evergreen.V82.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , to : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V82.Id.Id Evergreen.V82.Id.MailId) Evergreen.V82.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V82.Id.Id Evergreen.V82.Id.MailId
        , from : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , content : List Evergreen.V82.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V82.Id.Id Evergreen.V82.Id.MailId) (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId, Evergreen.V82.Animal.Animal ))
    | ServerChangeTool (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) Evergreen.V82.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId) (Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V82.Bounds.Bounds Evergreen.V82.Units.CellUnit) (List ( Evergreen.V82.Coord.Coord Evergreen.V82.Units.CellUnit, Evergreen.V82.GridCell.CellData )) (List ( Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId, Evergreen.V82.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V82.Id.Id Evergreen.V82.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
