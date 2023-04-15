module Evergreen.V75.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V75.Animal
import Evergreen.V75.Bounds
import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.Cursor
import Evergreen.V75.DisplayName
import Evergreen.V75.EmailAddress
import Evergreen.V75.Grid
import Evergreen.V75.GridCell
import Evergreen.V75.Id
import Evergreen.V75.IdDict
import Evergreen.V75.MailEditor
import Evergreen.V75.Point2d
import Evergreen.V75.Train
import Evergreen.V75.Units
import Evergreen.V75.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V75.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId) (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId) (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V75.Color.Colors
    | ToggleRailSplit (Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V75.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V75.MailEditor.Content
        , to : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V75.MailEditor.Content
        , to : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V75.Id.Id Evergreen.V75.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V75.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V75.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V75.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V75.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId (List Evergreen.V75.MailEditor.Content)
    , emailAddress : Evergreen.V75.EmailAddress.EmailAddress
    , inbox : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.MailId Evergreen.V75.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V75.Grid.GridChange
        , newCells : List (Evergreen.V75.Coord.Coord Evergreen.V75.Units.CellUnit)
        , newCows : List ( Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId, Evergreen.V75.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V75.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) (Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId) (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) (Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId) (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , user : Evergreen.V75.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId, Evergreen.V75.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V75.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) Evergreen.V75.Color.Colors
    | ServerToggleRailSplit (Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) Evergreen.V75.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , to : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V75.Id.Id Evergreen.V75.Id.MailId) Evergreen.V75.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V75.Id.Id Evergreen.V75.Id.MailId
        , from : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , content : List Evergreen.V75.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V75.Id.Id Evergreen.V75.Id.MailId) (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId, Evergreen.V75.Animal.Animal ))
    | ServerChangeTool (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) Evergreen.V75.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId) (Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V75.Bounds.Bounds Evergreen.V75.Units.CellUnit) (List ( Evergreen.V75.Coord.Coord Evergreen.V75.Units.CellUnit, Evergreen.V75.GridCell.CellData )) (List ( Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId, Evergreen.V75.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V75.Id.Id Evergreen.V75.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
