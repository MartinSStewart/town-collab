module Evergreen.V115.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V115.Animal
import Evergreen.V115.Bounds
import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.Cursor
import Evergreen.V115.DisplayName
import Evergreen.V115.EmailAddress
import Evergreen.V115.Grid
import Evergreen.V115.GridCell
import Evergreen.V115.Id
import Evergreen.V115.IdDict
import Evergreen.V115.MailEditor
import Evergreen.V115.Point2d
import Evergreen.V115.Tile
import Evergreen.V115.TimeOfDay
import Evergreen.V115.Train
import Evergreen.V115.Units
import Evergreen.V115.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
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
    { viewBounds : Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit)
    , newCells : List ( Evergreen.V115.Coord.Coord Evergreen.V115.Units.CellUnit, Evergreen.V115.GridCell.CellData )
    , newCows : List ( Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId, Evergreen.V115.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V115.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId) (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId) (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V115.Color.Colors
    | ToggleRailSplit (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V115.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V115.MailEditor.Content
        , to : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V115.MailEditor.Content
        , to : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V115.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V115.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V115.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.MailId Evergreen.V115.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V115.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V115.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V115.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId (List Evergreen.V115.MailEditor.Content)
    , emailAddress : Evergreen.V115.EmailAddress.EmailAddress
    , inbox : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.MailId Evergreen.V115.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V115.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V115.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    , endPosition : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V115.Grid.GridChange
        , newCells : List (Evergreen.V115.Coord.Coord Evergreen.V115.Units.CellUnit)
        , newAnimals : List ( Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId, Evergreen.V115.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V115.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId) (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId) (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
                , user : Evergreen.V115.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId, Evergreen.V115.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V115.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Color.Colors
    | ServerToggleRailSplit (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , to : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId) Evergreen.V115.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V115.Id.Id Evergreen.V115.Id.MailId
        , from : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , content : List Evergreen.V115.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId) (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId, Evergreen.V115.Animal.Animal ))
    | ServerChangeTool (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V115.Id.Id Evergreen.V115.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V115.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
