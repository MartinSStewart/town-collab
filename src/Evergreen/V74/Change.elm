module Evergreen.V74.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V74.Animal
import Evergreen.V74.Bounds
import Evergreen.V74.Color
import Evergreen.V74.Coord
import Evergreen.V74.Cursor
import Evergreen.V74.DisplayName
import Evergreen.V74.EmailAddress
import Evergreen.V74.Grid
import Evergreen.V74.GridCell
import Evergreen.V74.Id
import Evergreen.V74.IdDict
import Evergreen.V74.MailEditor
import Evergreen.V74.Point2d
import Evergreen.V74.Train
import Evergreen.V74.Units
import Evergreen.V74.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V74.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId) (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId) (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V74.Color.Colors
    | ToggleRailSplit (Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V74.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V74.MailEditor.Content
        , to : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V74.MailEditor.Content
        , to : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V74.Id.Id Evergreen.V74.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V74.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V74.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V74.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V74.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId (List Evergreen.V74.MailEditor.Content)
    , emailAddress : Evergreen.V74.EmailAddress.EmailAddress
    , inbox : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.MailId Evergreen.V74.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V74.Grid.GridChange
        , newCells : List (Evergreen.V74.Coord.Coord Evergreen.V74.Units.CellUnit)
        , newCows : List ( Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId, Evergreen.V74.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V74.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId) (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId) (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , user : Evergreen.V74.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId, Evergreen.V74.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V74.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.Color.Colors
    | ServerToggleRailSplit (Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , to : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V74.Id.Id Evergreen.V74.Id.MailId) Evergreen.V74.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V74.Id.Id Evergreen.V74.Id.MailId
        , from : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , content : List Evergreen.V74.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V74.Id.Id Evergreen.V74.Id.MailId) (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId, Evergreen.V74.Animal.Animal ))
    | ServerChangeTool (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V74.Bounds.Bounds Evergreen.V74.Units.CellUnit) (List ( Evergreen.V74.Coord.Coord Evergreen.V74.Units.CellUnit, Evergreen.V74.GridCell.CellData )) (List ( Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId, Evergreen.V74.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V74.Id.Id Evergreen.V74.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
