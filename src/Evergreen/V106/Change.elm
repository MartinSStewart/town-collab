module Evergreen.V106.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V106.Animal
import Evergreen.V106.Bounds
import Evergreen.V106.Color
import Evergreen.V106.Coord
import Evergreen.V106.Cursor
import Evergreen.V106.DisplayName
import Evergreen.V106.EmailAddress
import Evergreen.V106.Grid
import Evergreen.V106.GridCell
import Evergreen.V106.Id
import Evergreen.V106.IdDict
import Evergreen.V106.MailEditor
import Evergreen.V106.Point2d
import Evergreen.V106.Tile
import Evergreen.V106.TimeOfDay
import Evergreen.V106.Train
import Evergreen.V106.Units
import Evergreen.V106.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId)
    | AdminResetUpdateDuration


type alias Report =
    { reportedUser : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
    , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
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
    { viewBounds : Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit)
    , newCells : List ( Evergreen.V106.Coord.Coord Evergreen.V106.Units.CellUnit, Evergreen.V106.GridCell.CellData )
    , newCows : List ( Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId, Evergreen.V106.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V106.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId) (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId) (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V106.Color.Colors
    | ToggleRailSplit (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V106.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V106.MailEditor.Content
        , to : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V106.MailEditor.Content
        , to : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V106.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V106.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V106.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
    , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.MailId Evergreen.V106.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V106.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V106.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V106.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId (List Evergreen.V106.MailEditor.Content)
    , emailAddress : Evergreen.V106.EmailAddress.EmailAddress
    , inbox : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.MailId Evergreen.V106.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V106.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V106.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    , endPosition : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V106.Grid.GridChange
        , newCells : List (Evergreen.V106.Coord.Coord Evergreen.V106.Units.CellUnit)
        , newAnimals : List ( Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId, Evergreen.V106.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V106.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) (Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId) (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) (Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId) (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , user : Evergreen.V106.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId, Evergreen.V106.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V106.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) Evergreen.V106.Color.Colors
    | ServerToggleRailSplit (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) Evergreen.V106.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , to : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId) Evergreen.V106.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V106.Id.Id Evergreen.V106.Id.MailId
        , from : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , content : List Evergreen.V106.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId) (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId, Evergreen.V106.Animal.Animal ))
    | ServerChangeTool (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) Evergreen.V106.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId) (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V106.Id.Id Evergreen.V106.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V106.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
