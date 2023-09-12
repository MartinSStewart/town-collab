module Evergreen.V85.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V85.Animal
import Evergreen.V85.Bounds
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.Cursor
import Evergreen.V85.DisplayName
import Evergreen.V85.EmailAddress
import Evergreen.V85.Grid
import Evergreen.V85.GridCell
import Evergreen.V85.Id
import Evergreen.V85.IdDict
import Evergreen.V85.MailEditor
import Evergreen.V85.Point2d
import Evergreen.V85.Train
import Evergreen.V85.Units
import Evergreen.V85.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V85.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId) (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId) (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V85.Color.Colors
    | ToggleRailSplit (Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V85.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V85.MailEditor.Content
        , to : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V85.MailEditor.Content
        , to : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V85.Id.Id Evergreen.V85.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V85.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V85.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V85.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V85.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId (List Evergreen.V85.MailEditor.Content)
    , emailAddress : Evergreen.V85.EmailAddress.EmailAddress
    , inbox : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.MailId Evergreen.V85.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V85.Grid.GridChange
        , newCells : List (Evergreen.V85.Coord.Coord Evergreen.V85.Units.CellUnit)
        , newCows : List ( Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId, Evergreen.V85.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V85.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) (Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId) (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) (Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId) (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , user : Evergreen.V85.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId, Evergreen.V85.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V85.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) Evergreen.V85.Color.Colors
    | ServerToggleRailSplit (Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) Evergreen.V85.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , to : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V85.Id.Id Evergreen.V85.Id.MailId) Evergreen.V85.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V85.Id.Id Evergreen.V85.Id.MailId
        , from : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , content : List Evergreen.V85.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V85.Id.Id Evergreen.V85.Id.MailId) (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId, Evergreen.V85.Animal.Animal ))
    | ServerChangeTool (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) Evergreen.V85.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId) (Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V85.Bounds.Bounds Evergreen.V85.Units.CellUnit) (List ( Evergreen.V85.Coord.Coord Evergreen.V85.Units.CellUnit, Evergreen.V85.GridCell.CellData )) (List ( Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId, Evergreen.V85.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V85.Id.Id Evergreen.V85.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
