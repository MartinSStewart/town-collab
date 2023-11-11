module Evergreen.V110.Change exposing (..)

import Array
import AssocList
import Dict
import Duration
import Effect.Time
import Evergreen.V110.Animal
import Evergreen.V110.Bounds
import Evergreen.V110.Color
import Evergreen.V110.Coord
import Evergreen.V110.Cursor
import Evergreen.V110.DisplayName
import Evergreen.V110.EmailAddress
import Evergreen.V110.Grid
import Evergreen.V110.GridCell
import Evergreen.V110.Id
import Evergreen.V110.IdDict
import Evergreen.V110.MailEditor
import Evergreen.V110.Point2d
import Evergreen.V110.Tile
import Evergreen.V110.TimeOfDay
import Evergreen.V110.Train
import Evergreen.V110.Units
import Evergreen.V110.User
import List.Nonempty


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId)
    | AdminResetUpdateDuration


type alias Report =
    { reportedUser : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
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
    { viewBounds : Evergreen.V110.Bounds.Bounds Evergreen.V110.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V110.Bounds.Bounds Evergreen.V110.Units.CellUnit)
    , newCells : List ( Evergreen.V110.Coord.Coord Evergreen.V110.Units.CellUnit, Evergreen.V110.GridCell.CellData )
    , newCows : List ( Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId, Evergreen.V110.Animal.Animal )
    }


type LocalChange
    = LocalGridChange Evergreen.V110.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId) (Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit) Effect.Time.Posix
    | DropAnimal (Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId) (Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V110.Color.Colors
    | ToggleRailSplit (Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V110.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V110.MailEditor.Content
        , to : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V110.MailEditor.Content
        , to : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V110.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit)
    | SetTimeOfDay Evergreen.V110.TimeOfDay.TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V110.Tile.TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix


type alias BackendReport =
    { reportedUser : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.MailId Evergreen.V110.MailEditor.BackendMail
    , worldUpdateDurations : Array.Array Duration.Duration
    , totalGridCells : Int
    }


type alias LoggedIn_ =
    { userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V110.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V110.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V110.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.UserId (List Evergreen.V110.MailEditor.Content)
    , emailAddress : Evergreen.V110.EmailAddress.EmailAddress
    , inbox : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.MailId Evergreen.V110.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : Evergreen.V110.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V110.Tile.TileGroup
    , showNotifications : Bool
    , notifications : List (Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    }


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit
    , endPosition : Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V110.Grid.GridChange
        , newCells : List (Evergreen.V110.Coord.Coord Evergreen.V110.Units.CellUnit)
        , newAnimals : List ( Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId, Evergreen.V110.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V110.Coord.RawCellCoord Int
        }
    | ServerPickupAnimal (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) (Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId) (Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) (Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId) (Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) (Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId)
    | ServerUserConnected
        { maybeLoggedIn :
            Maybe
                { userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
                , user : Evergreen.V110.User.FrontendUser
                }
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId, Evergreen.V110.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V110.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) Evergreen.V110.Color.Colors
    | ServerToggleRailSplit (Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) Evergreen.V110.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        , to : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId) Evergreen.V110.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.TrainId Evergreen.V110.Train.TrainDiff)
    | ServerWorldUpdateDuration Duration.Duration
    | ServerReceivedMail
        { mailId : Evergreen.V110.Id.Id Evergreen.V110.Id.MailId
        , from : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        , content : List Evergreen.V110.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId) (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId, Evergreen.V110.Animal.Animal ))
    | ServerChangeTool (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) Evergreen.V110.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V110.Id.Id Evergreen.V110.Id.UserId) (Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (List.Nonempty.Nonempty ( Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId, MovementChange ))


type Change
    = LocalChange (Evergreen.V110.Id.Id Evergreen.V110.Id.EventId) LocalChange
    | ServerChange ServerChange


type alias NotLoggedIn_ =
    { timeOfDay : Evergreen.V110.TimeOfDay.TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
