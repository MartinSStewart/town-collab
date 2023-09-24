module Evergreen.V88.Change exposing (..)

import Dict
import Effect.Time
import Evergreen.V88.Animal
import Evergreen.V88.Bounds
import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.Cursor
import Evergreen.V88.DisplayName
import Evergreen.V88.EmailAddress
import Evergreen.V88.Grid
import Evergreen.V88.GridCell
import Evergreen.V88.Id
import Evergreen.V88.IdDict
import Evergreen.V88.MailEditor
import Evergreen.V88.Point2d
import Evergreen.V88.Train
import Evergreen.V88.Units
import Evergreen.V88.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled


type alias Report =
    { reportedUser : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    }


type TimeOfDay
    = Automatic
    | AlwaysDay
    | AlwaysNight


type LocalChange
    = LocalGridChange Evergreen.V88.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId) (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId) (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V88.Color.Colors
    | ToggleRailSplit (Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V88.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V88.MailEditor.Content
        , to : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V88.MailEditor.Content
        , to : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V88.Id.Id Evergreen.V88.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V88.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit)
    | SetTimeOfDay TimeOfDay


type alias BackendReport =
    { reportedUser : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.MailId Evergreen.V88.MailEditor.BackendMail
    }


type alias LoggedIn_ =
    { userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V88.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V88.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V88.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId (List Evergreen.V88.MailEditor.Content)
    , emailAddress : Evergreen.V88.EmailAddress.EmailAddress
    , inbox : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.MailId Evergreen.V88.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : TimeOfDay
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V88.Grid.GridChange
        , newCells : List (Evergreen.V88.Coord.Coord Evergreen.V88.Units.CellUnit)
        , newCows : List ( Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId, Evergreen.V88.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V88.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) (Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId) (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) (Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId) (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , user : Evergreen.V88.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId, Evergreen.V88.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V88.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) Evergreen.V88.Color.Colors
    | ServerToggleRailSplit (Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) Evergreen.V88.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , to : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V88.Id.Id Evergreen.V88.Id.MailId) Evergreen.V88.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V88.Id.Id Evergreen.V88.Id.MailId
        , from : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , content : List Evergreen.V88.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V88.Id.Id Evergreen.V88.Id.MailId) (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId, Evergreen.V88.Animal.Animal ))
    | ServerChangeTool (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) Evergreen.V88.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId) (Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V88.Bounds.Bounds Evergreen.V88.Units.CellUnit) (List ( Evergreen.V88.Coord.Coord Evergreen.V88.Units.CellUnit, Evergreen.V88.GridCell.CellData )) (List ( Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId, Evergreen.V88.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V88.Id.Id Evergreen.V88.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type alias NotLoggedIn_ =
    { timeOfDay : TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
