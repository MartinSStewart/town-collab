module Evergreen.V89.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V89.Animal
import Evergreen.V89.Bounds
import Evergreen.V89.Color
import Evergreen.V89.Coord
import Evergreen.V89.Cursor
import Evergreen.V89.DisplayName
import Evergreen.V89.EmailAddress
import Evergreen.V89.Grid
import Evergreen.V89.GridCell
import Evergreen.V89.Id
import Evergreen.V89.IdDict
import Evergreen.V89.MailEditor
import Evergreen.V89.Point2d
import Evergreen.V89.Train
import Evergreen.V89.Units
import Evergreen.V89.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled
    | AdminDeleteMail (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId)


type alias Report =
    { reportedUser : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    }


type TimeOfDay
    = Automatic
    | AlwaysDay
    | AlwaysNight


type LocalChange
    = LocalGridChange Evergreen.V89.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId) (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId) (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V89.Color.Colors
    | ToggleRailSplit (Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V89.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V89.MailEditor.Content
        , to : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V89.MailEditor.Content
        , to : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V89.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit)
    | SetTimeOfDay TimeOfDay


type alias BackendReport =
    { reportedUser : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.MailId Evergreen.V89.MailEditor.BackendMail
    }


type alias LoggedIn_ =
    { userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V89.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V89.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V89.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId (List Evergreen.V89.MailEditor.Content)
    , emailAddress : Evergreen.V89.EmailAddress.EmailAddress
    , inbox : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.MailId Evergreen.V89.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : TimeOfDay
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V89.Grid.GridChange
        , newCells : List (Evergreen.V89.Coord.Coord Evergreen.V89.Units.CellUnit)
        , newCows : List ( Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId, Evergreen.V89.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V89.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) (Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId) (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) (Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId) (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        , user : Evergreen.V89.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId, Evergreen.V89.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V89.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) Evergreen.V89.Color.Colors
    | ServerToggleRailSplit (Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) Evergreen.V89.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        , to : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId) Evergreen.V89.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V89.Id.Id Evergreen.V89.Id.MailId
        , from : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        , content : List Evergreen.V89.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId) (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId, Evergreen.V89.Animal.Animal ))
    | ServerChangeTool (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) Evergreen.V89.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId) (Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V89.Bounds.Bounds Evergreen.V89.Units.CellUnit) (List ( Evergreen.V89.Coord.Coord Evergreen.V89.Units.CellUnit, Evergreen.V89.GridCell.CellData )) (List ( Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId, Evergreen.V89.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V89.Id.Id Evergreen.V89.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type alias NotLoggedIn_ =
    { timeOfDay : TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
