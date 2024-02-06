module Evergreen.V124.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V124.Animal
import Evergreen.V124.Bounds
import Evergreen.V124.Color
import Evergreen.V124.Coord
import Evergreen.V124.Cursor
import Evergreen.V124.DisplayName
import Evergreen.V124.EmailAddress
import Evergreen.V124.Grid
import Evergreen.V124.GridCell
import Evergreen.V124.Hyperlink
import Evergreen.V124.Id
import Evergreen.V124.IdDict
import Evergreen.V124.MailEditor
import Evergreen.V124.Point2d
import Evergreen.V124.Tile
import Evergreen.V124.TimeOfDay
import Evergreen.V124.Train
import Evergreen.V124.Units
import Evergreen.V124.User
import List.Nonempty
import Set


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
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
    { viewBounds : Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit)
    , newCells : List ( Evergreen.V124.Coord.Coord Evergreen.V124.Units.CellUnit, Evergreen.V124.GridCell.CellData )
    , newCows : List ( Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId, Evergreen.V124.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V124.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId) (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId) (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V124.Color.Colors
    | ToggleRailSplit (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V124.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V124.MailEditor.Content
        , to : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V124.MailEditor.Content
        , to : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V124.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V124.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V124.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Evergreen.V124.Hyperlink.Hyperlink


type alias BackendReport =
    { reportedUser : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.MailId Evergreen.V124.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V124.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V124.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V124.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId (List Evergreen.V124.MailEditor.Content)
    , emailAddress : Evergreen.V124.EmailAddress.EmailAddress
    , inbox : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.MailId Evergreen.V124.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V124.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V124.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set.Set String
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    , endPosition : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V124.Grid.GridChange
        , newCells : List (Evergreen.V124.Coord.Coord Evergreen.V124.Units.CellUnit)
        , newAnimals : List ( Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId, Evergreen.V124.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V124.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId) (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId) (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
                , user : Evergreen.V124.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId, Evergreen.V124.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V124.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Color.Colors
    | ServerToggleRailSplit (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , to : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId) Evergreen.V124.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V124.Id.Id Evergreen.V124.Id.MailId
        , from : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , content : List Evergreen.V124.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId) (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId, Evergreen.V124.Animal.Animal ))
    | ServerChangeTool (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) Evergreen.V124.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V124.Id.Id Evergreen.V124.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V124.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
