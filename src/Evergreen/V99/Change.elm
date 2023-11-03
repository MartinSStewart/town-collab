module Evergreen.V99.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V99.Animal
import Evergreen.V99.Bounds
import Evergreen.V99.Color
import Evergreen.V99.Coord
import Evergreen.V99.Cursor
import Evergreen.V99.DisplayName
import Evergreen.V99.EmailAddress
import Evergreen.V99.Grid
import Evergreen.V99.GridCell
import Evergreen.V99.Id
import Evergreen.V99.IdDict
import Evergreen.V99.MailEditor
import Evergreen.V99.Point2d
import Evergreen.V99.Tile
import Evergreen.V99.TimeOfDay
import Evergreen.V99.Train
import Evergreen.V99.Units
import Evergreen.V99.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId)


type alias Report =
    { reportedUser : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
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
    { viewBounds : Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit)
    , newCells : List ( Evergreen.V99.Coord.Coord Evergreen.V99.Units.CellUnit, Evergreen.V99.GridCell.CellData )
    , newCows : List ( Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId, Evergreen.V99.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V99.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId) (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId) (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V99.Color.Colors
    | ToggleRailSplit (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V99.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V99.MailEditor.Content
        , to : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V99.MailEditor.Content
        , to : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V99.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V99.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V99.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.MailId Evergreen.V99.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V99.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V99.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V99.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId (List Evergreen.V99.MailEditor.Content)
    , emailAddress : Evergreen.V99.EmailAddress.EmailAddress
    , inbox : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.MailId Evergreen.V99.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V99.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V99.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    , endPosition : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V99.Grid.GridChange
        , newCells : List (Evergreen.V99.Coord.Coord Evergreen.V99.Units.CellUnit)
        , newAnimals : List ( Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId, Evergreen.V99.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V99.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) (Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId) (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) (Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId) (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , user : Evergreen.V99.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId, Evergreen.V99.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V99.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) Evergreen.V99.Color.Colors
    | ServerToggleRailSplit (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) Evergreen.V99.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , to : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId) Evergreen.V99.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V99.Id.Id Evergreen.V99.Id.MailId
        , from : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , content : List Evergreen.V99.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId) (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId, Evergreen.V99.Animal.Animal ))
    | ServerChangeTool (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) Evergreen.V99.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId) (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V99.Id.Id Evergreen.V99.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V99.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
