module Evergreen.V134.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V134.Animal
import Evergreen.V134.Bounds
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.Cursor
import Evergreen.V134.DisplayName
import Evergreen.V134.EmailAddress
import Evergreen.V134.Grid
import Evergreen.V134.GridCell
import Evergreen.V134.Hyperlink
import Evergreen.V134.Id
import Evergreen.V134.MailEditor
import Evergreen.V134.Name
import Evergreen.V134.Npc
import Evergreen.V134.Point2d
import Evergreen.V134.Tile
import Evergreen.V134.TimeOfDay
import Evergreen.V134.Train
import Evergreen.V134.Units
import Evergreen.V134.User
import List.Nonempty
import SeqDict
import Set


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
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
    { viewBounds : Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit)
    , newCells : List ( Evergreen.V134.Coord.Coord Evergreen.V134.Units.CellUnit, Evergreen.V134.GridCell.CellData )
    , newCows : List ( Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId, Evergreen.V134.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V134.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimalOrNpc Evergreen.V134.Cursor.AnimalOrNpcId (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit) Effect.Time.Posix
    | DropAnimalOrNpc Evergreen.V134.Cursor.AnimalOrNpcId (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V134.Color.Colors
    | ToggleRailSplit (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V134.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V134.MailEditor.Content
        , to : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V134.MailEditor.Content
        , to : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V134.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V134.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V134.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Evergreen.V134.Hyperlink.Hyperlink
    | RenameAnimalOrNpc Evergreen.V134.Cursor.AnimalOrNpcId Evergreen.V134.Name.Name


type alias BackendReport =
    { reportedUser : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
            , connectionCount : Int
            }
    , reported : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (List.Nonempty.Nonempty BackendReport)
    , mail : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V134.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V134.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V134.Coord.RawCellCoord Int
    , mailDrafts : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (List Evergreen.V134.MailEditor.Content)
    , emailAddress : Evergreen.V134.EmailAddress.EmailAddress
    , inbox : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V134.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V134.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set.Set String
    }


type alias NpcMovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , endPosition : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , visitedPositions : List.Nonempty.Nonempty (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit)
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , endPosition : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V134.Grid.GridChange
        , newCells : List (Evergreen.V134.Coord.Coord Evergreen.V134.Units.CellUnit)
        , newAnimals : List ( Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId, Evergreen.V134.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V134.Coord.RawCellCoord Int
        }
    | ServerPickupAnimalOrNpc (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Cursor.AnimalOrNpcId (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimalOrNpc (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Cursor.AnimalOrNpcId (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit) Effect.Time.Posix
    | ServerMoveCursor (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
                , user : Evergreen.V134.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId, Evergreen.V134.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V134.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Color.Colors
    | ServerToggleRailSplit (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , to : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast
        { trainDiff : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Evergreen.V134.Train.TrainDiff
        , maybeNewNpc : Maybe ( Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId, Evergreen.V134.Npc.Npc )
        , relocatedNpcs : List ( Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId, Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit )
        , movementChanges : List ( Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId, NpcMovementChange )
        }
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V134.Id.Id Evergreen.V134.Id.MailId
        , from : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , content : List Evergreen.V134.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId, Evergreen.V134.Animal.Animal ))
    | ServerChangeTool (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix
    | FakeServerAnimationFrame
        { previousTime : Effect.Time.Posix
        , currentTime : Effect.Time.Posix
        }
    | ServerRenameAnimalOrNpc Evergreen.V134.Cursor.AnimalOrNpcId Evergreen.V134.Name.Name


type Change
    = LocalChange (Evergreen.V134.Id.Id Evergreen.V134.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V134.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
