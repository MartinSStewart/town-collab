module Evergreen.V95.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V95.Animal
import Evergreen.V95.Bounds
import Evergreen.V95.Color
import Evergreen.V95.Coord
import Evergreen.V95.Cursor
import Evergreen.V95.DisplayName
import Evergreen.V95.EmailAddress
import Evergreen.V95.Grid
import Evergreen.V95.GridCell
import Evergreen.V95.Id
import Evergreen.V95.IdDict
import Evergreen.V95.MailEditor
import Evergreen.V95.Point2d
import Evergreen.V95.Tile
import Evergreen.V95.TimeOfDay
import Evergreen.V95.Train
import Evergreen.V95.Units
import Evergreen.V95.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId)


type alias Report =
    { reportedUser : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
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
    { viewBounds : Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit)
    , newCells : List ( Evergreen.V95.Coord.Coord Evergreen.V95.Units.CellUnit, Evergreen.V95.GridCell.CellData )
    , newCows : List ( Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId, Evergreen.V95.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V95.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId) (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId) (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V95.Color.Colors
    | ToggleRailSplit (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V95.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V95.MailEditor.Content
        , to : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V95.MailEditor.Content
        , to : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V95.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V95.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V95.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.MailId Evergreen.V95.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias LoggedIn_ =
    { userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V95.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V95.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V95.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId (List Evergreen.V95.MailEditor.Content)
    , emailAddress : Evergreen.V95.EmailAddress.EmailAddress
    , inbox : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.MailId Evergreen.V95.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V95.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V95.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
    , endPosition : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V95.Grid.GridChange
        , newCells : List (Evergreen.V95.Coord.Coord Evergreen.V95.Units.CellUnit)
        , newAnimals : List ( Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId, Evergreen.V95.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V95.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) (Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId) (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) (Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId) (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , user : Evergreen.V95.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId, Evergreen.V95.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V95.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) Evergreen.V95.Color.Colors
    | ServerToggleRailSplit (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) Evergreen.V95.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , to : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId) Evergreen.V95.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V95.Id.Id Evergreen.V95.Id.MailId
        , from : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , content : List Evergreen.V95.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId) (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId, Evergreen.V95.Animal.Animal ))
    | ServerChangeTool (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) Evergreen.V95.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId) (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V95.Id.Id Evergreen.V95.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V95.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
