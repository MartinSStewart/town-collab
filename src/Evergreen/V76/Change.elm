module Evergreen.V76.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V76.Animal
import Evergreen.V76.Bounds
import Evergreen.V76.Color
import Evergreen.V76.Coord
import Evergreen.V76.Cursor
import Evergreen.V76.DisplayName
import Evergreen.V76.EmailAddress
import Evergreen.V76.Grid
import Evergreen.V76.GridCell
import Evergreen.V76.Id
import Evergreen.V76.IdDict
import Evergreen.V76.MailEditor
import Evergreen.V76.Point2d
import Evergreen.V76.Train
import Evergreen.V76.Units
import Evergreen.V76.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    }


type LocalChange
    = LocalGridChange Evergreen.V76.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId) (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId) (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V76.Color.Colors
    | ToggleRailSplit (Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V76.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V76.MailEditor.Content
        , to : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V76.MailEditor.Content
        , to : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V76.Id.Id Evergreen.V76.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V76.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit)


type alias BackendReport =
    { reportedUser : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId (List.Nonempty.Nonempty BackendReport)
    }


type alias LoggedIn_ =
    { userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V76.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V76.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V76.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId (List Evergreen.V76.MailEditor.Content)
    , emailAddress : Evergreen.V76.EmailAddress.EmailAddress
    , inbox : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.MailId Evergreen.V76.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V76.Grid.GridChange
        , newCells : List (Evergreen.V76.Coord.Coord Evergreen.V76.Units.CellUnit)
        , newCows : List ( Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId, Evergreen.V76.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V76.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId) (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId) (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , user : Evergreen.V76.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId, Evergreen.V76.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V76.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Color.Colors
    | ServerToggleRailSplit (Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , to : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V76.Id.Id Evergreen.V76.Id.MailId) Evergreen.V76.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V76.Id.Id Evergreen.V76.Id.MailId
        , from : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , content : List Evergreen.V76.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V76.Id.Id Evergreen.V76.Id.MailId) (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId, Evergreen.V76.Animal.Animal ))
    | ServerChangeTool (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) Evergreen.V76.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V76.Bounds.Bounds Evergreen.V76.Units.CellUnit) (List ( Evergreen.V76.Coord.Coord Evergreen.V76.Units.CellUnit, Evergreen.V76.GridCell.CellData )) (List ( Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId, Evergreen.V76.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V76.Id.Id Evergreen.V76.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn
