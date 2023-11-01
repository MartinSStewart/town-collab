module Evergreen.V97.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V97.Animal
import Evergreen.V97.Bounds
import Evergreen.V97.Color
import Evergreen.V97.Coord
import Evergreen.V97.Cursor
import Evergreen.V97.DisplayName
import Evergreen.V97.EmailAddress
import Evergreen.V97.Grid
import Evergreen.V97.GridCell
import Evergreen.V97.Id
import Evergreen.V97.IdDict
import Evergreen.V97.MailEditor
import Evergreen.V97.Point2d
import Evergreen.V97.Tile
import Evergreen.V97.TimeOfDay
import Evergreen.V97.Train
import Evergreen.V97.Units
import Evergreen.V97.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId)


type alias Report =
    { reportedUser : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
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
    { viewBounds : Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit)
    , newCells : List ( Evergreen.V97.Coord.Coord Evergreen.V97.Units.CellUnit, Evergreen.V97.GridCell.CellData )
    , newCows : List ( Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId, Evergreen.V97.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V97.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId) (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId) (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V97.Color.Colors
    | ToggleRailSplit (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V97.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V97.MailEditor.Content
        , to : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V97.MailEditor.Content
        , to : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V97.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V97.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V97.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.MailId Evergreen.V97.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias LoggedIn_ =
    { userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V97.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V97.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V97.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId (List Evergreen.V97.MailEditor.Content)
    , emailAddress : Evergreen.V97.EmailAddress.EmailAddress
    , inbox : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.MailId Evergreen.V97.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V97.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V97.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
    , endPosition : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V97.Grid.GridChange
        , newCells : List (Evergreen.V97.Coord.Coord Evergreen.V97.Units.CellUnit)
        , newAnimals : List ( Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId, Evergreen.V97.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V97.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId) (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId) (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , user : Evergreen.V97.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId, Evergreen.V97.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V97.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Color.Colors
    | ServerToggleRailSplit (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , to : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId) Evergreen.V97.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V97.Id.Id Evergreen.V97.Id.MailId
        , from : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , content : List Evergreen.V97.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId) (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId, Evergreen.V97.Animal.Animal ))
    | ServerChangeTool (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) Evergreen.V97.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V97.Id.Id Evergreen.V97.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V97.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
