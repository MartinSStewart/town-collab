module Evergreen.V107.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V107.Animal
import Evergreen.V107.Bounds
import Evergreen.V107.Color
import Evergreen.V107.Coord
import Evergreen.V107.Cursor
import Evergreen.V107.DisplayName
import Evergreen.V107.EmailAddress
import Evergreen.V107.Grid
import Evergreen.V107.GridCell
import Evergreen.V107.Id
import Evergreen.V107.IdDict
import Evergreen.V107.MailEditor
import Evergreen.V107.Point2d
import Evergreen.V107.Tile
import Evergreen.V107.TimeOfDay
import Evergreen.V107.Train
import Evergreen.V107.Units
import Evergreen.V107.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId)
    | AdminResetUpdateDuration


type alias Report =
    { reportedUser : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
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
    { viewBounds : Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit)
    , newCells : List ( Evergreen.V107.Coord.Coord Evergreen.V107.Units.CellUnit, Evergreen.V107.GridCell.CellData )
    , newCows : List ( Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId, Evergreen.V107.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V107.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId) (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId) (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V107.Color.Colors
    | ToggleRailSplit (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V107.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V107.MailEditor.Content
        , to : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V107.MailEditor.Content
        , to : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V107.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V107.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V107.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.MailId Evergreen.V107.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V107.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V107.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V107.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId (List Evergreen.V107.MailEditor.Content)
    , emailAddress : Evergreen.V107.EmailAddress.EmailAddress
    , inbox : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.MailId Evergreen.V107.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V107.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V107.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    , endPosition : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V107.Grid.GridChange
        , newCells : List (Evergreen.V107.Coord.Coord Evergreen.V107.Units.CellUnit)
        , newAnimals : List ( Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId, Evergreen.V107.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V107.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) (Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId) (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) (Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId) (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , user : Evergreen.V107.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId, Evergreen.V107.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V107.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) Evergreen.V107.Color.Colors
    | ServerToggleRailSplit (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) Evergreen.V107.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , to : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId) Evergreen.V107.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V107.Id.Id Evergreen.V107.Id.MailId
        , from : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , content : List Evergreen.V107.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId) (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId, Evergreen.V107.Animal.Animal ))
    | ServerChangeTool (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) Evergreen.V107.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId) (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V107.Id.Id Evergreen.V107.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V107.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
