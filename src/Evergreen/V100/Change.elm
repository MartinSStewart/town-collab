module Evergreen.V100.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V100.Animal
import Evergreen.V100.Bounds
import Evergreen.V100.Color
import Evergreen.V100.Coord
import Evergreen.V100.Cursor
import Evergreen.V100.DisplayName
import Evergreen.V100.EmailAddress
import Evergreen.V100.Grid
import Evergreen.V100.GridCell
import Evergreen.V100.Id
import Evergreen.V100.IdDict
import Evergreen.V100.MailEditor
import Evergreen.V100.Point2d
import Evergreen.V100.Tile
import Evergreen.V100.TimeOfDay
import Evergreen.V100.Train
import Evergreen.V100.Units
import Evergreen.V100.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId)
    | AdminResetUpdateDuration


type alias Report =
    { reportedUser : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
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
    { viewBounds : Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit)
    , newCells : List ( Evergreen.V100.Coord.Coord Evergreen.V100.Units.CellUnit, Evergreen.V100.GridCell.CellData )
    , newCows : List ( Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId, Evergreen.V100.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V100.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId) (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId) (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V100.Color.Colors
    | ToggleRailSplit (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V100.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V100.MailEditor.Content
        , to : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V100.MailEditor.Content
        , to : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V100.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V100.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V100.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.MailId Evergreen.V100.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V100.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V100.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V100.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId (List Evergreen.V100.MailEditor.Content)
    , emailAddress : Evergreen.V100.EmailAddress.EmailAddress
    , inbox : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.MailId Evergreen.V100.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V100.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V100.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    , endPosition : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V100.Grid.GridChange
        , newCells : List (Evergreen.V100.Coord.Coord Evergreen.V100.Units.CellUnit)
        , newAnimals : List ( Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId, Evergreen.V100.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V100.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) (Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId) (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) (Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId) (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , user : Evergreen.V100.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId, Evergreen.V100.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V100.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) Evergreen.V100.Color.Colors
    | ServerToggleRailSplit (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) Evergreen.V100.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , to : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId) Evergreen.V100.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V100.Id.Id Evergreen.V100.Id.MailId
        , from : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , content : List Evergreen.V100.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId) (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId, Evergreen.V100.Animal.Animal ))
    | ServerChangeTool (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) Evergreen.V100.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId) (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V100.Id.Id Evergreen.V100.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V100.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
