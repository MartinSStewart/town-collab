module Evergreen.V114.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V114.Animal
import Evergreen.V114.Bounds
import Evergreen.V114.Color
import Evergreen.V114.Coord
import Evergreen.V114.Cursor
import Evergreen.V114.DisplayName
import Evergreen.V114.EmailAddress
import Evergreen.V114.Grid
import Evergreen.V114.GridCell
import Evergreen.V114.Id
import Evergreen.V114.IdDict
import Evergreen.V114.MailEditor
import Evergreen.V114.Point2d
import Evergreen.V114.Tile
import Evergreen.V114.TimeOfDay
import Evergreen.V114.Train
import Evergreen.V114.Units
import Evergreen.V114.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
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
    { viewBounds : Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit)
    , newCells : List ( Evergreen.V114.Coord.Coord Evergreen.V114.Units.CellUnit, Evergreen.V114.GridCell.CellData )
    , newCows : List ( Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId, Evergreen.V114.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V114.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId) (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId) (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V114.Color.Colors
    | ToggleRailSplit (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V114.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V114.MailEditor.Content
        , to : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V114.MailEditor.Content
        , to : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V114.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V114.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V114.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.MailId Evergreen.V114.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V114.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V114.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V114.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId (List Evergreen.V114.MailEditor.Content)
    , emailAddress : Evergreen.V114.EmailAddress.EmailAddress
    , inbox : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.MailId Evergreen.V114.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V114.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V114.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    , endPosition : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V114.Grid.GridChange
        , newCells : List (Evergreen.V114.Coord.Coord Evergreen.V114.Units.CellUnit)
        , newAnimals : List ( Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId, Evergreen.V114.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V114.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId) (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId) (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
                , user : Evergreen.V114.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId, Evergreen.V114.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V114.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Color.Colors
    | ServerToggleRailSplit (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        , to : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId) Evergreen.V114.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V114.Id.Id Evergreen.V114.Id.MailId
        , from : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        , content : List Evergreen.V114.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId) (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId, Evergreen.V114.Animal.Animal ))
    | ServerChangeTool (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V114.Id.Id Evergreen.V114.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V114.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
