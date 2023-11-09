module Evergreen.V109.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V109.Animal
import Evergreen.V109.Bounds
import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.Cursor
import Evergreen.V109.DisplayName
import Evergreen.V109.EmailAddress
import Evergreen.V109.Grid
import Evergreen.V109.GridCell
import Evergreen.V109.Id
import Evergreen.V109.IdDict
import Evergreen.V109.MailEditor
import Evergreen.V109.Point2d
import Evergreen.V109.Tile
import Evergreen.V109.TimeOfDay
import Evergreen.V109.Train
import Evergreen.V109.Units
import Evergreen.V109.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId)
    | AdminResetUpdateDuration


type alias Report =
    { reportedUser : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
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
    { viewBounds : Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit)
    , newCells : List ( Evergreen.V109.Coord.Coord Evergreen.V109.Units.CellUnit, Evergreen.V109.GridCell.CellData )
    , newCows : List ( Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId, Evergreen.V109.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V109.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId) (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId) (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V109.Color.Colors
    | ToggleRailSplit (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V109.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V109.MailEditor.Content
        , to : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V109.MailEditor.Content
        , to : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V109.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V109.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V109.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.MailId Evergreen.V109.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V109.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V109.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V109.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId (List Evergreen.V109.MailEditor.Content)
    , emailAddress : Evergreen.V109.EmailAddress.EmailAddress
    , inbox : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.MailId Evergreen.V109.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V109.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V109.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    , endPosition : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V109.Grid.GridChange
        , newCells : List (Evergreen.V109.Coord.Coord Evergreen.V109.Units.CellUnit)
        , newAnimals : List ( Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId, Evergreen.V109.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V109.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId) (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId) (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
                , user : Evergreen.V109.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId, Evergreen.V109.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V109.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Color.Colors
    | ServerToggleRailSplit (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , to : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId) Evergreen.V109.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V109.Id.Id Evergreen.V109.Id.MailId
        , from : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , content : List Evergreen.V109.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId) (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId, Evergreen.V109.Animal.Animal ))
    | ServerChangeTool (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) Evergreen.V109.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V109.Id.Id Evergreen.V109.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V109.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
