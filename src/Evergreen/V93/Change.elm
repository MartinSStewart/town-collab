module Evergreen.V93.Change exposing (..)

import AssocList
import Dict
import Effect.Time
import Evergreen.V93.Animal
import Evergreen.V93.Bounds
import Evergreen.V93.Color
import Evergreen.V93.Coord
import Evergreen.V93.Cursor
import Evergreen.V93.DisplayName
import Evergreen.V93.EmailAddress
import Evergreen.V93.Grid
import Evergreen.V93.GridCell
import Evergreen.V93.Id
import Evergreen.V93.IdDict
import Evergreen.V93.MailEditor
import Evergreen.V93.Point2d
import Evergreen.V93.Tile
import Evergreen.V93.TimeOfDay
import Evergreen.V93.Train
import Evergreen.V93.Units
import Evergreen.V93.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled
    | AdminDeleteMail (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId)


type alias Report =
    { reportedUser : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    }


type TileHotkey
    = Hotkey0
    | Hotkey1
    | Hotkey2
    | Hotkey3
    | Hotkey4
    | Hotkey5
    | Hotkey6
    | Hotkey7
    | Hotkey8
    | Hotkey9


type alias ViewBoundsChange2 =
    { viewBounds : Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit)
    , newCells : List ( Evergreen.V93.Coord.Coord Evergreen.V93.Units.CellUnit, Evergreen.V93.GridCell.CellData )
    , newCows : List ( Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId, Evergreen.V93.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V93.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId) (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId) (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V93.Color.Colors
    | ToggleRailSplit (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V93.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V93.MailEditor.Content
        , to : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V93.MailEditor.Content
        , to : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V93.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V93.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V93.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.MailId Evergreen.V93.MailEditor.BackendMail
    }


type alias LoggedIn_ =
    { userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V93.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V93.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V93.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId (List Evergreen.V93.MailEditor.Content)
    , emailAddress : Evergreen.V93.EmailAddress.EmailAddress
    , inbox : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.MailId Evergreen.V93.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V93.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V93.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V93.Grid.GridChange
        , newCells : List (Evergreen.V93.Coord.Coord Evergreen.V93.Units.CellUnit)
        , newCows : List ( Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId, Evergreen.V93.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V93.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId) (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId) (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , user : Evergreen.V93.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId, Evergreen.V93.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V93.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Color.Colors
    | ServerToggleRailSplit (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , to : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId) Evergreen.V93.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V93.Id.Id Evergreen.V93.Id.MailId
        , from : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , content : List Evergreen.V93.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId) (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId, Evergreen.V93.Animal.Animal ))
    | ServerChangeTool (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) Evergreen.V93.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled
    | ServerLogout


type Change
    = LocalChange (Evergreen.V93.Id.Id Evergreen.V93.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V93.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
