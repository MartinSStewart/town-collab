module Evergreen.V111.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V111.Animal
import Evergreen.V111.Bounds
import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.Cursor
import Evergreen.V111.DisplayName
import Evergreen.V111.EmailAddress
import Evergreen.V111.Grid
import Evergreen.V111.GridCell
import Evergreen.V111.Id
import Evergreen.V111.IdDict
import Evergreen.V111.MailEditor
import Evergreen.V111.Point2d
import Evergreen.V111.Tile
import Evergreen.V111.TimeOfDay
import Evergreen.V111.Train
import Evergreen.V111.Units
import Evergreen.V111.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
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
    { viewBounds : Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit)
    , newCells : List ( Evergreen.V111.Coord.Coord Evergreen.V111.Units.CellUnit, Evergreen.V111.GridCell.CellData )
    , newCows : List ( Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId, Evergreen.V111.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V111.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId) (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId) (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V111.Color.Colors
    | ToggleRailSplit (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V111.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V111.MailEditor.Content
        , to : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V111.MailEditor.Content
        , to : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V111.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V111.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V111.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.MailId Evergreen.V111.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V111.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V111.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V111.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId (List Evergreen.V111.MailEditor.Content)
    , emailAddress : Evergreen.V111.EmailAddress.EmailAddress
    , inbox : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.MailId Evergreen.V111.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V111.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V111.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    , endPosition : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V111.Grid.GridChange
        , newCells : List (Evergreen.V111.Coord.Coord Evergreen.V111.Units.CellUnit)
        , newAnimals : List ( Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId, Evergreen.V111.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V111.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) (Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId) (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) (Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId) (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
                , user : Evergreen.V111.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId, Evergreen.V111.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V111.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) Evergreen.V111.Color.Colors
    | ServerToggleRailSplit (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) Evergreen.V111.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        , to : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId) Evergreen.V111.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V111.Id.Id Evergreen.V111.Id.MailId
        , from : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        , content : List Evergreen.V111.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId) (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId, Evergreen.V111.Animal.Animal ))
    | ServerChangeTool (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) Evergreen.V111.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId) (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V111.Id.Id Evergreen.V111.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V111.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
