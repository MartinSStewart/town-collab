module Evergreen.V126.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V126.Animal
import Evergreen.V126.Bounds
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.Cursor
import Evergreen.V126.DisplayName
import Evergreen.V126.EmailAddress
import Evergreen.V126.Grid
import Evergreen.V126.GridCell
import Evergreen.V126.Hyperlink
import Evergreen.V126.Id
import Evergreen.V126.IdDict
import Evergreen.V126.MailEditor
import Evergreen.V126.Name
import Evergreen.V126.Npc
import Evergreen.V126.Point2d
import Evergreen.V126.Tile
import Evergreen.V126.TimeOfDay
import Evergreen.V126.Train
import Evergreen.V126.Units
import Evergreen.V126.User
import List.Nonempty
import Set


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
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
    { viewBounds : Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit)
    , newCells : List ( Evergreen.V126.Coord.Coord Evergreen.V126.Units.CellUnit, Evergreen.V126.GridCell.CellData )
    , newCows : List ( Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId, Evergreen.V126.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V126.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimalOrNpc Evergreen.V126.Cursor.AnimalOrNpcId (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit) Effect.Time.Posix
    | DropAnimalOrNpc Evergreen.V126.Cursor.AnimalOrNpcId (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V126.Color.Colors
    | ToggleRailSplit (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V126.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V126.MailEditor.Content
        , to : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V126.MailEditor.Content
        , to : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V126.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V126.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V126.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Evergreen.V126.Hyperlink.Hyperlink
    | RenameAnimalOrNpc Evergreen.V126.Cursor.AnimalOrNpcId Evergreen.V126.Name.Name


type alias BackendReport =
    { reportedUser : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.MailId Evergreen.V126.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V126.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V126.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V126.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId (List Evergreen.V126.MailEditor.Content)
    , emailAddress : Evergreen.V126.EmailAddress.EmailAddress
    , inbox : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.MailId Evergreen.V126.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V126.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V126.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set.Set String
    }


type alias NpcMovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , endPosition : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , visitedPositions : List.Nonempty.Nonempty (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit)
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , endPosition : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V126.Grid.GridChange
        , newCells : List (Evergreen.V126.Coord.Coord Evergreen.V126.Units.CellUnit)
        , newAnimals : List ( Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId, Evergreen.V126.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V126.Coord.RawCellCoord Int
        }
    | ServerPickupAnimalOrNpc (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) Evergreen.V126.Cursor.AnimalOrNpcId (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimalOrNpc (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) Evergreen.V126.Cursor.AnimalOrNpcId (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit) Effect.Time.Posix
    | ServerMoveCursor (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
                , user : Evergreen.V126.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId, Evergreen.V126.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V126.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) Evergreen.V126.Color.Colors
    | ServerToggleRailSplit (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) Evergreen.V126.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        , to : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId) Evergreen.V126.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast
        { trainDiff : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.TrainId Evergreen.V126.Train.TrainDiff
        , maybeNewNpc : Maybe ( Evergreen.V126.Id.Id Evergreen.V126.Id.NpcId, Evergreen.V126.Npc.Npc )
        , relocatedNpcs : List ( Evergreen.V126.Id.Id Evergreen.V126.Id.NpcId, Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit )
        , movementChanges : List ( Evergreen.V126.Id.Id Evergreen.V126.Id.NpcId, NpcMovementChange )
        }
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V126.Id.Id Evergreen.V126.Id.MailId
        , from : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        , content : List Evergreen.V126.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId) (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId, Evergreen.V126.Animal.Animal ))
    | ServerChangeTool (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) Evergreen.V126.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId) (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix
    | FakeServerAnimationFrame
        { previousTime : Effect.Time.Posix
        , currentTime : Effect.Time.Posix
        }
    | ServerRenameAnimalOrNpc Evergreen.V126.Cursor.AnimalOrNpcId Evergreen.V126.Name.Name


type Change
    = LocalChange (Evergreen.V126.Id.Id Evergreen.V126.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V126.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
