module Evergreen.V125.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V125.Animal
import Evergreen.V125.Bounds
import Evergreen.V125.Color
import Evergreen.V125.Coord
import Evergreen.V125.Cursor
import Evergreen.V125.DisplayName
import Evergreen.V125.EmailAddress
import Evergreen.V125.Grid
import Evergreen.V125.GridCell
import Evergreen.V125.Hyperlink
import Evergreen.V125.Id
import Evergreen.V125.IdDict
import Evergreen.V125.MailEditor
import Evergreen.V125.Point2d
import Evergreen.V125.Tile
import Evergreen.V125.TimeOfDay
import Evergreen.V125.Train
import Evergreen.V125.Units
import Evergreen.V125.User
import List.Nonempty
import Set


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type alias Report =
    { reportedUser : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
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
    { viewBounds : Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit)
    , newCells : List ( Evergreen.V125.Coord.Coord Evergreen.V125.Units.CellUnit, Evergreen.V125.GridCell.CellData )
    , newCows : List ( Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId, Evergreen.V125.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V125.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId) (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId) (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V125.Color.Colors
    | ToggleRailSplit (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V125.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V125.MailEditor.Content
        , to : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V125.MailEditor.Content
        , to : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V125.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V125.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V125.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Evergreen.V125.Hyperlink.Hyperlink


type alias BackendReport =
    { reportedUser : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.MailId Evergreen.V125.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V125.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V125.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V125.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId (List Evergreen.V125.MailEditor.Content)
    , emailAddress : Evergreen.V125.EmailAddress.EmailAddress
    , inbox : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.MailId Evergreen.V125.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V125.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V125.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set.Set String
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    , endPosition : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V125.Grid.GridChange
        , newCells : List (Evergreen.V125.Coord.Coord Evergreen.V125.Units.CellUnit)
        , newAnimals : List ( Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId, Evergreen.V125.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V125.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId) (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId) (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
                , user : Evergreen.V125.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId, Evergreen.V125.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V125.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Color.Colors
    | ServerToggleRailSplit (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , to : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId) Evergreen.V125.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V125.Id.Id Evergreen.V125.Id.MailId
        , from : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , content : List Evergreen.V125.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId) (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId, Evergreen.V125.Animal.Animal ))
    | ServerChangeTool (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type Change
    = LocalChange (Evergreen.V125.Id.Id Evergreen.V125.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V125.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
