module Evergreen.V113.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V113.Animal
import Evergreen.V113.Bounds
import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.Cursor
import Evergreen.V113.DisplayName
import Evergreen.V113.EmailAddress
import Evergreen.V113.Grid
import Evergreen.V113.GridCell
import Evergreen.V113.Id
import Evergreen.V113.IdDict
import Evergreen.V113.MailEditor
import Evergreen.V113.Point2d
import Evergreen.V113.Tile
import Evergreen.V113.TimeOfDay
import Evergreen.V113.Train
import Evergreen.V113.Units
import Evergreen.V113.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
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
    { viewBounds : Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit)
    , newCells : List ( Evergreen.V113.Coord.Coord Evergreen.V113.Units.CellUnit, Evergreen.V113.GridCell.CellData )
    , newCows : List ( Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId, Evergreen.V113.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V113.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId) (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId) (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V113.Color.Colors
    | ToggleRailSplit (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V113.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V113.MailEditor.Content
        , to : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V113.MailEditor.Content
        , to : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V113.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V113.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V113.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.MailId Evergreen.V113.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V113.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V113.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V113.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId (List Evergreen.V113.MailEditor.Content)
    , emailAddress : Evergreen.V113.EmailAddress.EmailAddress
    , inbox : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.MailId Evergreen.V113.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V113.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V113.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    , endPosition : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V113.Grid.GridChange
        , newCells : List (Evergreen.V113.Coord.Coord Evergreen.V113.Units.CellUnit)
        , newAnimals : List ( Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId, Evergreen.V113.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V113.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) (Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId) (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) (Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId) (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
                , user : Evergreen.V113.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId, Evergreen.V113.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V113.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) Evergreen.V113.Color.Colors
    | ServerToggleRailSplit (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) Evergreen.V113.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        , to : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId) Evergreen.V113.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V113.Id.Id Evergreen.V113.Id.MailId
        , from : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        , content : List Evergreen.V113.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId) (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId, Evergreen.V113.Animal.Animal ))
    | ServerChangeTool (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) Evergreen.V113.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId) (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V113.Id.Id Evergreen.V113.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V113.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
