module Evergreen.V81.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V81.Animal
import Evergreen.V81.Bounds
import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.Cursor
import Evergreen.V81.DisplayName
import Evergreen.V81.EmailAddress
import Evergreen.V81.Grid
import Evergreen.V81.GridCell
import Evergreen.V81.Id
import Evergreen.V81.IdDict
import Evergreen.V81.MailEditor
import Evergreen.V81.Point2d
import Evergreen.V81.Train
import Evergreen.V81.Units
import Evergreen.V81.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V81.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId) (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId) (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V81.Color.Colors
    | ToggleRailSplit (Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V81.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V81.MailEditor.Content
        , to : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V81.MailEditor.Content
        , to : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V81.Id.Id Evergreen.V81.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V81.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V81.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V81.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V81.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId (List Evergreen.V81.MailEditor.Content)
    , emailAddress : Evergreen.V81.EmailAddress.EmailAddress
    , inbox : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.MailId Evergreen.V81.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V81.Grid.GridChange
        , newCells : List (Evergreen.V81.Coord.Coord Evergreen.V81.Units.CellUnit)
        , newCows : List ( Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId, Evergreen.V81.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V81.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) (Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId) (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) (Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId) (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , user : Evergreen.V81.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId, Evergreen.V81.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V81.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) Evergreen.V81.Color.Colors
    | ServerToggleRailSplit (Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) Evergreen.V81.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , to : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V81.Id.Id Evergreen.V81.Id.MailId) Evergreen.V81.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V81.Id.Id Evergreen.V81.Id.MailId
        , from : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , content : List Evergreen.V81.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V81.Id.Id Evergreen.V81.Id.MailId) (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId, Evergreen.V81.Animal.Animal ))
    | ServerChangeTool (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) Evergreen.V81.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId) (Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V81.Bounds.Bounds Evergreen.V81.Units.CellUnit) (List ( Evergreen.V81.Coord.Coord Evergreen.V81.Units.CellUnit, Evergreen.V81.GridCell.CellData )) (List ( Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId, Evergreen.V81.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V81.Id.Id Evergreen.V81.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
