module Evergreen.V116.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V116.Animal
import Evergreen.V116.Bounds
import Evergreen.V116.Color
import Evergreen.V116.Coord
import Evergreen.V116.Cursor
import Evergreen.V116.DisplayName
import Evergreen.V116.EmailAddress
import Evergreen.V116.Grid
import Evergreen.V116.GridCell
import Evergreen.V116.Hyperlink
import Evergreen.V116.Id
import Evergreen.V116.IdDict
import Evergreen.V116.MailEditor
import Evergreen.V116.Point2d
import Evergreen.V116.Tile
import Evergreen.V116.TimeOfDay
import Evergreen.V116.Train
import Evergreen.V116.Units
import Evergreen.V116.User
import List.Nonempty
import Set


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
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
    { viewBounds : Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit)
    , newCells : List ( Evergreen.V116.Coord.Coord Evergreen.V116.Units.CellUnit, Evergreen.V116.GridCell.CellData )
    , newCows : List ( Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId, Evergreen.V116.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V116.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId) (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId) (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V116.Color.Colors
    | ToggleRailSplit (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V116.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V116.MailEditor.Content
        , to : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V116.MailEditor.Content
        , to : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V116.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V116.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V116.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Evergreen.V116.Hyperlink.Hyperlink


type alias BackendReport =
    { reportedUser : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.MailId Evergreen.V116.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V116.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V116.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V116.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId (List Evergreen.V116.MailEditor.Content)
    , emailAddress : Evergreen.V116.EmailAddress.EmailAddress
    , inbox : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.MailId Evergreen.V116.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V116.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V116.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set.Set String
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    , endPosition : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V116.Grid.GridChange
        , newCells : List (Evergreen.V116.Coord.Coord Evergreen.V116.Units.CellUnit)
        , newAnimals : List ( Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId, Evergreen.V116.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V116.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId) (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId) (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
                , user : Evergreen.V116.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId, Evergreen.V116.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V116.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Color.Colors
    | ServerToggleRailSplit (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , to : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId) Evergreen.V116.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V116.Id.Id Evergreen.V116.Id.MailId
        , from : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , content : List Evergreen.V116.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId) (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId, Evergreen.V116.Animal.Animal ))
    | ServerChangeTool (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V116.Id.Id Evergreen.V116.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V116.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
