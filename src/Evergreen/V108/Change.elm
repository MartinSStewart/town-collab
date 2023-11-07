module Evergreen.V108.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V108.Animal
import Evergreen.V108.Bounds
import Evergreen.V108.Color
import Evergreen.V108.Coord
import Evergreen.V108.Cursor
import Evergreen.V108.DisplayName
import Evergreen.V108.EmailAddress
import Evergreen.V108.Grid
import Evergreen.V108.GridCell
import Evergreen.V108.Id
import Evergreen.V108.IdDict
import Evergreen.V108.MailEditor
import Evergreen.V108.Point2d
import Evergreen.V108.Tile
import Evergreen.V108.TimeOfDay
import Evergreen.V108.Train
import Evergreen.V108.Units
import Evergreen.V108.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId)
    | AdminResetUpdateDuration


type alias Report =
    { reportedUser : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
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
    { viewBounds : Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit)
    , newCells : List ( Evergreen.V108.Coord.Coord Evergreen.V108.Units.CellUnit, Evergreen.V108.GridCell.CellData )
    , newCows : List ( Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId, Evergreen.V108.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V108.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId) (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId) (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V108.Color.Colors
    | ToggleRailSplit (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V108.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V108.MailEditor.Content
        , to : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V108.MailEditor.Content
        , to : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V108.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V108.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V108.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.MailId Evergreen.V108.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V108.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V108.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V108.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId (List Evergreen.V108.MailEditor.Content)
    , emailAddress : Evergreen.V108.EmailAddress.EmailAddress
    , inbox : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.MailId Evergreen.V108.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V108.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V108.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    , endPosition : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V108.Grid.GridChange
        , newCells : List (Evergreen.V108.Coord.Coord Evergreen.V108.Units.CellUnit)
        , newAnimals : List ( Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId, Evergreen.V108.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V108.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId) (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId) (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , user : Evergreen.V108.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId, Evergreen.V108.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V108.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Color.Colors
    | ServerToggleRailSplit (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , to : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId) Evergreen.V108.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V108.Id.Id Evergreen.V108.Id.MailId
        , from : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , content : List Evergreen.V108.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId) (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId, Evergreen.V108.Animal.Animal ))
    | ServerChangeTool (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) Evergreen.V108.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V108.Id.Id Evergreen.V108.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V108.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
