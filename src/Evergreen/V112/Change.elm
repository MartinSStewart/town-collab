module Evergreen.V112.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V112.Animal
import Evergreen.V112.Bounds
import Evergreen.V112.Color
import Evergreen.V112.Coord
import Evergreen.V112.Cursor
import Evergreen.V112.DisplayName
import Evergreen.V112.EmailAddress
import Evergreen.V112.Grid
import Evergreen.V112.GridCell
import Evergreen.V112.Id
import Evergreen.V112.IdDict
import Evergreen.V112.MailEditor
import Evergreen.V112.Point2d
import Evergreen.V112.Tile
import Evergreen.V112.TimeOfDay
import Evergreen.V112.Train
import Evergreen.V112.Units
import Evergreen.V112.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
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
    { viewBounds : Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit)
    , newCells : List ( Evergreen.V112.Coord.Coord Evergreen.V112.Units.CellUnit, Evergreen.V112.GridCell.CellData )
    , newCows : List ( Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId, Evergreen.V112.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V112.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId) (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId) (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V112.Color.Colors
    | ToggleRailSplit (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V112.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V112.MailEditor.Content
        , to : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V112.MailEditor.Content
        , to : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V112.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V112.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V112.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.MailId Evergreen.V112.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V112.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V112.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V112.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId (List Evergreen.V112.MailEditor.Content)
    , emailAddress : Evergreen.V112.EmailAddress.EmailAddress
    , inbox : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.MailId Evergreen.V112.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V112.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V112.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    , endPosition : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V112.Grid.GridChange
        , newCells : List (Evergreen.V112.Coord.Coord Evergreen.V112.Units.CellUnit)
        , newAnimals : List ( Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId, Evergreen.V112.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V112.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId) (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId) (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
                , user : Evergreen.V112.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId, Evergreen.V112.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V112.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Color.Colors
    | ServerToggleRailSplit (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , to : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId) Evergreen.V112.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V112.Id.Id Evergreen.V112.Id.MailId
        , from : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , content : List Evergreen.V112.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId) (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId, Evergreen.V112.Animal.Animal ))
    | ServerChangeTool (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V112.Id.Id Evergreen.V112.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V112.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
