module Evergreen.V123.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V123.Animal
import Evergreen.V123.Bounds
import Evergreen.V123.Color
import Evergreen.V123.Coord
import Evergreen.V123.Cursor
import Evergreen.V123.DisplayName
import Evergreen.V123.EmailAddress
import Evergreen.V123.Grid
import Evergreen.V123.GridCell
import Evergreen.V123.Hyperlink
import Evergreen.V123.Id
import Evergreen.V123.IdDict
import Evergreen.V123.MailEditor
import Evergreen.V123.Point2d
import Evergreen.V123.Tile
import Evergreen.V123.TimeOfDay
import Evergreen.V123.Train
import Evergreen.V123.Units
import Evergreen.V123.User
import List.Nonempty
import Set


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
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
    { viewBounds : Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit)
    , newCells : List ( Evergreen.V123.Coord.Coord Evergreen.V123.Units.CellUnit, Evergreen.V123.GridCell.CellData )
    , newCows : List ( Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId, Evergreen.V123.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V123.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId) (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId) (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V123.Color.Colors
    | ToggleRailSplit (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V123.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V123.MailEditor.Content
        , to : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V123.MailEditor.Content
        , to : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V123.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V123.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V123.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Evergreen.V123.Hyperlink.Hyperlink


type alias BackendReport =
    { reportedUser : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.MailId Evergreen.V123.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V123.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V123.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V123.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId (List Evergreen.V123.MailEditor.Content)
    , emailAddress : Evergreen.V123.EmailAddress.EmailAddress
    , inbox : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.MailId Evergreen.V123.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V123.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V123.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set.Set String
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    , endPosition : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V123.Grid.GridChange
        , newCells : List (Evergreen.V123.Coord.Coord Evergreen.V123.Units.CellUnit)
        , newAnimals : List ( Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId, Evergreen.V123.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V123.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) (Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId) (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) (Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId) (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
                , user : Evergreen.V123.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId, Evergreen.V123.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V123.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) Evergreen.V123.Color.Colors
    | ServerToggleRailSplit (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) Evergreen.V123.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        , to : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId) Evergreen.V123.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V123.Id.Id Evergreen.V123.Id.MailId
        , from : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        , content : List Evergreen.V123.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId) (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId, Evergreen.V123.Animal.Animal ))
    | ServerChangeTool (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) Evergreen.V123.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId) (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V123.Id.Id Evergreen.V123.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V123.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
