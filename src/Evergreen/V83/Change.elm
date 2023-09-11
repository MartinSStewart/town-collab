module Evergreen.V83.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V83.Animal
import Evergreen.V83.Bounds
import Evergreen.V83.Color
import Evergreen.V83.Coord
import Evergreen.V83.Cursor
import Evergreen.V83.DisplayName
import Evergreen.V83.EmailAddress
import Evergreen.V83.Grid
import Evergreen.V83.GridCell
import Evergreen.V83.Id
import Evergreen.V83.IdDict
import Evergreen.V83.MailEditor
import Evergreen.V83.Point2d
import Evergreen.V83.Train
import Evergreen.V83.Units
import Evergreen.V83.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V83.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId) (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId) (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V83.Color.Colors
    | ToggleRailSplit (Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V83.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V83.MailEditor.Content
        , to : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V83.MailEditor.Content
        , to : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V83.Id.Id Evergreen.V83.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V83.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V83.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V83.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V83.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId (List Evergreen.V83.MailEditor.Content)
    , emailAddress : Evergreen.V83.EmailAddress.EmailAddress
    , inbox : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.MailId Evergreen.V83.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V83.Grid.GridChange
        , newCells : List (Evergreen.V83.Coord.Coord Evergreen.V83.Units.CellUnit)
        , newCows : List ( Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId, Evergreen.V83.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V83.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) (Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId) (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) (Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId) (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , user : Evergreen.V83.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId, Evergreen.V83.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V83.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) Evergreen.V83.Color.Colors
    | ServerToggleRailSplit (Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) Evergreen.V83.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , to : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V83.Id.Id Evergreen.V83.Id.MailId) Evergreen.V83.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V83.Id.Id Evergreen.V83.Id.MailId
        , from : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , content : List Evergreen.V83.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V83.Id.Id Evergreen.V83.Id.MailId) (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId, Evergreen.V83.Animal.Animal ))
    | ServerChangeTool (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) Evergreen.V83.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId) (Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V83.Bounds.Bounds Evergreen.V83.Units.CellUnit) (List ( Evergreen.V83.Coord.Coord Evergreen.V83.Units.CellUnit, Evergreen.V83.GridCell.CellData )) (List ( Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId, Evergreen.V83.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V83.Id.Id Evergreen.V83.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
