module LocalGrid exposing
    ( LocalGrid
    , LocalGrid_
    , OutMsg(..)
    , addReported
    , ctrlOrMeta
    , currentTool
    , currentUserId
    , deleteMail
    , getCowsForCell
    , incrementUndoCurrent
    , init
    , keyDown
    , localModel
    , removeReported
    , restoreMail
    , setTileHotkey
    , update
    , updateFromBackend
    )

import Animal exposing (Animal, AnimalType(..))
import AssocList
import Bounds exposing (Bounds)
import Change exposing (AdminChange(..), AreTrainsDisabled, BackendReport, Change(..), ClientChange(..), LocalChange(..), ServerChange(..), TileHotkey, UserStatus(..))
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (Cursor)
import Dict exposing (Dict)
import Effect.Time
import Grid exposing (Grid, GridData)
import GridCell
import Id exposing (AnimalId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import List.Nonempty exposing (Nonempty)
import LocalModel exposing (LocalModel)
import MailEditor exposing (FrontendMail, MailStatus(..), MailStatus2(..))
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Random
import Terrain exposing (TerrainType(..))
import Tile exposing (Tile, TileGroup)
import Tool exposing (Tool(..))
import Train exposing (Train)
import Undo
import Units exposing (CellLocalUnit, CellUnit, WorldUnit)
import User exposing (FrontendUser, InviteTree)


type LocalGrid
    = LocalGrid LocalGrid_


type alias LocalGrid_ =
    { grid : Grid
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , animals : IdDict AnimalId Animal
    , cursors : IdDict UserId Cursor
    , users : IdDict UserId FrontendUser
    , inviteTree : InviteTree
    , mail : IdDict MailId FrontendMail
    , trains : IdDict TrainId Train
    , trainsDisabled : AreTrainsDisabled
    }


currentUserId : { a | localModel : LocalModel Change LocalGrid } -> Maybe (Id UserId)
currentUserId model =
    case localModel model.localModel |> .userStatus of
        LoggedIn loggedIn ->
            Just loggedIn.userId

        NotLoggedIn _ ->
            Nothing


currentTool :
    { a | localModel : LocalModel Change LocalGrid, pressedKeys : List Keyboard.Key, currentTool : Tool }
    -> Tool
currentTool model =
    case currentUserId model of
        Just _ ->
            if ctrlOrMeta model then
                TilePickerTool

            else
                model.currentTool

        Nothing ->
            HandTool


ctrlOrMeta : { a | pressedKeys : List Keyboard.Key } -> Bool
ctrlOrMeta model =
    keyDown Keyboard.Control model || keyDown Keyboard.Meta model


keyDown : Keyboard.Key -> { a | pressedKeys : List Keyboard.Key } -> Bool
keyDown key { pressedKeys } =
    List.any ((==) key) pressedKeys


localModel : LocalModel a LocalGrid -> LocalGrid_
localModel localModel_ =
    LocalModel.localModel localModel_ |> (\(LocalGrid a) -> a)


init :
    { a
        | userStatus : UserStatus
        , grid : GridData
        , viewBounds : Bounds CellUnit
        , cows : IdDict AnimalId Animal
        , cursors : IdDict UserId Cursor
        , users : IdDict UserId FrontendUser
        , inviteTree : InviteTree
        , mail : IdDict MailId FrontendMail
        , trains : IdDict TrainId Train
        , trainsDisabled : AreTrainsDisabled
    }
    -> LocalModel Change LocalGrid
init { grid, userStatus, viewBounds, cows, cursors, users, inviteTree, mail, trains, trainsDisabled } =
    LocalGrid
        { grid = Grid.dataToGrid grid
        , userStatus = userStatus
        , viewBounds = viewBounds
        , animals = cows
        , cursors = cursors
        , users = users
        , inviteTree = inviteTree
        , mail = mail
        , trains = trains
        , trainsDisabled = trainsDisabled
        }
        |> LocalModel.init


update : Change -> LocalModel Change LocalGrid -> ( LocalModel Change LocalGrid, OutMsg )
update change localModel_ =
    LocalModel.update config change localModel_


updateFromBackend : Nonempty Change -> LocalModel Change LocalGrid -> ( LocalModel Change LocalGrid, List OutMsg )
updateFromBackend changes localModel_ =
    LocalModel.updateFromBackend config changes localModel_


incrementUndoCurrent : Coord CellUnit -> Coord CellLocalUnit -> Dict RawCellCoord Int -> Dict RawCellCoord Int
incrementUndoCurrent cellPosition localPosition undoCurrent =
    cellPosition
        :: List.map Tuple.first (Grid.closeNeighborCells cellPosition localPosition)
        |> List.foldl
            (\neighborPos undoCurrent2 ->
                Dict.update
                    (Coord.toTuple neighborPos)
                    (Maybe.withDefault 0 >> (+) 1 >> Just)
                    undoCurrent2
            )
            undoCurrent


type OutMsg
    = TilesRemoved
        (List
            { tile : Tile
            , position : Coord WorldUnit
            , userId : Id UserId
            , colors : Colors
            }
        )
    | OtherUserCursorMoved { userId : Id UserId, previousPosition : Maybe (Point2d WorldUnit WorldUnit) }
    | NoOutMsg
    | HandColorOrNameChanged (Id UserId)
    | RailToggledBySelf (Coord WorldUnit)
    | RailToggledByAnother (Coord WorldUnit)
    | TeleportTrainHome (Id TrainId)
    | TrainLeaveHome (Id TrainId)
    | TrainsUpdated (IdDict TrainId Train.TrainDiff)
    | ReceivedMail
    | ExportMail (List MailEditor.Content)
    | ImportMail


updateLocalChange : LocalChange -> LocalGrid_ -> ( LocalGrid_, OutMsg )
updateLocalChange localChange model =
    case localChange of
        LocalGridChange gridChange ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    let
                        ( cellPosition, localPosition ) =
                            Grid.worldToCellAndLocalCoord gridChange.position

                        change =
                            Grid.addChange (Grid.localChangeToChange loggedIn.userId gridChange) model.grid
                    in
                    ( { model
                        | userStatus =
                            { loggedIn
                                | redoHistory = []
                                , undoCurrent = incrementUndoCurrent cellPosition localPosition loggedIn.undoCurrent
                            }
                                |> LoggedIn
                        , grid =
                            if Bounds.contains cellPosition model.viewBounds then
                                change.grid

                            else
                                model.grid
                      }
                        |> addAnimals change.newCells
                    , TilesRemoved change.removed
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        LocalRedo ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    case Undo.redo loggedIn of
                        Just newLoggedIn ->
                            { model
                                | userStatus = LoggedIn newLoggedIn
                                , grid = Grid.moveUndoPoint loggedIn.userId newLoggedIn.undoCurrent model.grid
                            }

                        Nothing ->
                            model

                NotLoggedIn _ ->
                    model
            , NoOutMsg
            )

        LocalUndo ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    case Undo.undo loggedIn of
                        Just newLoggedIn ->
                            { model
                                | userStatus = LoggedIn newLoggedIn
                                , grid =
                                    Grid.moveUndoPoint
                                        loggedIn.userId
                                        (Dict.map (\_ a -> -a) loggedIn.undoCurrent)
                                        model.grid
                            }

                        Nothing ->
                            model

                NotLoggedIn _ ->
                    model
            , NoOutMsg
            )

        LocalAddUndo ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model | userStatus = Undo.add loggedIn |> LoggedIn }

                NotLoggedIn _ ->
                    model
            , NoOutMsg
            )

        InvalidChange ->
            ( model, NoOutMsg )

        PickupCow cowId position time ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    pickupCow loggedIn.userId cowId position time model

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        DropCow cowId position _ ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    dropCow loggedIn.userId cowId position model

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        MoveCursor position ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    moveCursor loggedIn.userId position model

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        ChangeHandColor colors ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | users = IdDict.update2 loggedIn.userId (\user -> { user | handColor = colors }) model.users
                      }
                    , HandColorOrNameChanged loggedIn.userId
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        ToggleRailSplit coord ->
            ( { model | grid = Grid.toggleRailSplit coord model.grid }, RailToggledBySelf coord )

        ChangeDisplayName displayName ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | users = IdDict.update2 loggedIn.userId (\user -> { user | name = displayName }) model.users
                      }
                    , HandColorOrNameChanged loggedIn.userId
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        SubmitMail submitMail ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    let
                        mailId =
                            IdDict.size model.mail |> Id.fromInt
                    in
                    ( { model
                        | userStatus =
                            LoggedIn
                                { loggedIn
                                    | mailDrafts = IdDict.remove submitMail.to loggedIn.mailDrafts
                                    , adminData =
                                        case loggedIn.adminData of
                                            Just adminData ->
                                                { adminData
                                                    | mail =
                                                        IdDict.insert mailId
                                                            { to = submitMail.to
                                                            , from = loggedIn.userId
                                                            , status = MailWaitingPickup
                                                            , content = submitMail.content
                                                            }
                                                            adminData.mail
                                                }
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                }
                        , mail =
                            IdDict.insert mailId
                                { to = submitMail.to, from = loggedIn.userId, status = MailWaitingPickup }
                                model.mail
                      }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        UpdateDraft updateDraft ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | userStatus =
                            LoggedIn
                                { loggedIn
                                    | mailDrafts =
                                        IdDict.insert updateDraft.to updateDraft.content loggedIn.mailDrafts
                                }
                      }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        TeleportHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update2 trainId (Train.startTeleportingHome time) model.trains }
            , TeleportTrainHome trainId
            )

        LeaveHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update2 trainId (Train.leaveHome time) model.trains }
            , TrainLeaveHome trainId
            )

        ViewedMail mailId ->
            ( { model
                | userStatus =
                    case model.userStatus of
                        LoggedIn loggedIn ->
                            { loggedIn
                                | inbox = IdDict.update2 mailId (\mail -> { mail | isViewed = True }) loggedIn.inbox
                                , adminData = Maybe.map (viewMail mailId) loggedIn.adminData
                            }
                                |> LoggedIn

                        NotLoggedIn _ ->
                            model.userStatus
              }
                |> viewMail mailId
            , NoOutMsg
            )

        SetAllowEmailNotifications allow ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model | userStatus = LoggedIn { loggedIn | allowEmailNotifications = allow } }

                NotLoggedIn _ ->
                    model
            , NoOutMsg
            )

        ChangeTool tool ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model
                        | cursors =
                            IdDict.update2 loggedIn.userId (\cursor -> { cursor | currentTool = tool }) model.cursors
                    }

                NotLoggedIn _ ->
                    model
            , NoOutMsg
            )

        ReportVandalism report ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model | userStatus = LoggedIn { loggedIn | reports = report :: loggedIn.reports } }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        RemoveReport position ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | userStatus =
                            LoggedIn
                                { loggedIn
                                    | reports =
                                        List.filter (\report -> report.position /= position) loggedIn.reports
                                }
                      }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        AdminChange adminChange ->
            case adminChange of
                AdminResetSessions ->
                    ( case model.userStatus of
                        LoggedIn loggedIn ->
                            case loggedIn.adminData of
                                Just adminData ->
                                    { model
                                        | userStatus =
                                            LoggedIn
                                                { loggedIn
                                                    | adminData =
                                                        { adminData
                                                            | userSessions =
                                                                List.map
                                                                    (\data -> { data | connectionCount = 0 })
                                                                    adminData.userSessions
                                                        }
                                                            |> Just
                                                }
                                    }

                                Nothing ->
                                    model

                        NotLoggedIn _ ->
                            model
                    , NoOutMsg
                    )

                AdminSetGridReadOnly isGridReadOnly ->
                    updateLoggedIn model (\loggedIn -> { loggedIn | isGridReadOnly = isGridReadOnly })

                AdminSetTrainsDisabled trainsDisabled ->
                    ( { model | trainsDisabled = trainsDisabled }, NoOutMsg )

                AdminDeleteMail mailId time ->
                    ( case model.userStatus of
                        LoggedIn loggedIn ->
                            { model
                                | userStatus =
                                    LoggedIn
                                        { loggedIn
                                            | adminData = Maybe.map (deleteMail mailId time) loggedIn.adminData
                                        }
                            }
                                |> deleteMail mailId time

                        NotLoggedIn _ ->
                            model
                    , NoOutMsg
                    )

                AdminRestoreMail mailId ->
                    ( case model.userStatus of
                        LoggedIn loggedIn ->
                            { model
                                | userStatus =
                                    LoggedIn
                                        { loggedIn
                                            | adminData = Maybe.map (restoreMail mailId) loggedIn.adminData
                                        }
                            }
                                |> restoreMail mailId

                        NotLoggedIn _ ->
                            model
                    , NoOutMsg
                    )

        SetTimeOfDay timeOfDay ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model | userStatus = LoggedIn { loggedIn | timeOfDay = timeOfDay } }

                NotLoggedIn notLoggedIn ->
                    { model | userStatus = NotLoggedIn { notLoggedIn | timeOfDay = timeOfDay } }
            , NoOutMsg
            )

        SetTileHotkey tileHotkey tileGroup ->
            updateLoggedIn model (setTileHotkey tileHotkey tileGroup)

        ShowNotifications showNotifications ->
            updateLoggedIn model (\loggedIn -> { loggedIn | showNotifications = showNotifications })


setTileHotkey :
    TileHotkey
    -> TileGroup
    -> { c | tileHotkeys : AssocList.Dict TileHotkey TileGroup }
    -> { c | tileHotkeys : AssocList.Dict TileHotkey TileGroup }
setTileHotkey hotkey tileGroup user =
    { user
        | tileHotkeys =
            AssocList.filter (\_ value -> value /= tileGroup) user.tileHotkeys
                |> AssocList.insert hotkey tileGroup
    }


updateLoggedIn : LocalGrid_ -> (Change.LoggedIn_ -> Change.LoggedIn_) -> ( LocalGrid_, OutMsg )
updateLoggedIn model updateFunc =
    ( case model.userStatus of
        LoggedIn loggedIn ->
            { model
                | userStatus =
                    updateFunc loggedIn |> LoggedIn
            }

        NotLoggedIn _ ->
            model
    , NoOutMsg
    )


viewMail :
    Id MailId
    -> { b | mail : IdDict MailId { c | status : MailStatus } }
    -> { b | mail : IdDict MailId { c | status : MailStatus } }
viewMail mailId model =
    { model
        | mail =
            IdDict.update2
                mailId
                (\mail ->
                    { mail
                        | status =
                            case mail.status of
                                MailReceived data ->
                                    MailReceivedAndViewed data

                                _ ->
                                    mail.status
                    }
                )
                model.mail
    }


restoreMail :
    Id MailId
    -> { b | mail : IdDict MailId { c | status : MailStatus } }
    -> { b | mail : IdDict MailId { c | status : MailStatus } }
restoreMail mailId model =
    { model
        | mail =
            IdDict.update2
                mailId
                (\mail ->
                    case mail.status of
                        MailDeletedByAdmin deleted ->
                            { mail
                                | status =
                                    case deleted.previousStatus of
                                        MailWaitingPickup2 ->
                                            MailWaitingPickup

                                        MailInTransit2 id ->
                                            MailWaitingPickup

                                        MailReceived2 record ->
                                            MailReceived record

                                        MailReceivedAndViewed2 record ->
                                            MailReceivedAndViewed record
                            }

                        _ ->
                            mail
                )
                model.mail
    }


deleteMail :
    Id MailId
    -> Effect.Time.Posix
    -> { b | mail : IdDict MailId { c | status : MailStatus } }
    -> { b | mail : IdDict MailId { c | status : MailStatus } }
deleteMail mailId time model =
    { model
        | mail =
            IdDict.update2
                mailId
                (\mail ->
                    { mail
                        | status =
                            case mail.status of
                                MailWaitingPickup ->
                                    MailDeletedByAdmin
                                        { previousStatus = MailWaitingPickup2
                                        , deletedAt = time
                                        }

                                MailInTransit id ->
                                    MailDeletedByAdmin
                                        { previousStatus = MailInTransit2 id
                                        , deletedAt = time
                                        }

                                MailReceived record ->
                                    MailDeletedByAdmin
                                        { previousStatus = MailReceived2 record
                                        , deletedAt = time
                                        }

                                MailReceivedAndViewed record ->
                                    MailDeletedByAdmin
                                        { previousStatus = MailReceivedAndViewed2 record
                                        , deletedAt = time
                                        }

                                MailDeletedByAdmin _ ->
                                    mail.status
                    }
                )
                model.mail
    }


updateServerChange : ServerChange -> LocalGrid_ -> ( LocalGrid_, OutMsg )
updateServerChange serverChange model =
    case serverChange of
        ServerGridChange { gridChange, newCows } ->
            let
                model2 =
                    { model | animals = IdDict.fromList newCows |> IdDict.union model.animals }
            in
            ( if
                Bounds.contains
                    (Grid.worldToCellAndLocalCoord gridChange.position |> Tuple.first)
                    model2.viewBounds
              then
                { model2 | grid = Grid.addChange gridChange model2.grid |> .grid }

              else
                model2
            , NoOutMsg
            )

        ServerUndoPoint undoPoint ->
            ( { model | grid = Grid.moveUndoPoint undoPoint.userId undoPoint.undoPoints model.grid }
            , NoOutMsg
            )

        ServerPickupCow userId cowId position time ->
            pickupCow userId cowId position time model

        ServerDropCow userId cowId position ->
            dropCow userId cowId position model

        ServerMoveCursor userId position ->
            moveCursor userId position model

        ServerUserDisconnected userId ->
            ( { model | cursors = IdDict.remove userId model.cursors }
            , NoOutMsg
            )

        ServerChangeHandColor userId colors ->
            ( { model
                | users =
                    IdDict.update2
                        userId
                        (\user -> { user | handColor = colors })
                        model.users
              }
            , HandColorOrNameChanged userId
            )

        ServerUserConnected { userId, user, cowsSpawnedFromVisibleRegion } ->
            ( { model
                | users = IdDict.insert userId user model.users
                , animals = IdDict.fromList cowsSpawnedFromVisibleRegion |> IdDict.union model.animals
              }
            , HandColorOrNameChanged userId
            )

        ServerYouLoggedIn loggedIn user ->
            ( { model
                | userStatus = LoggedIn loggedIn
                , users = IdDict.insert loggedIn.userId user model.users
              }
            , HandColorOrNameChanged loggedIn.userId
            )

        ServerToggleRailSplit coord ->
            ( { model | grid = Grid.toggleRailSplit coord model.grid }, RailToggledByAnother coord )

        ServerChangeDisplayName userId displayName ->
            ( { model
                | users =
                    IdDict.update2
                        userId
                        (\user -> { user | name = displayName })
                        model.users
              }
            , HandColorOrNameChanged userId
            )

        ServerSubmitMail { to, from } ->
            let
                mailId =
                    IdDict.size model.mail |> Id.fromInt
            in
            ( { model
                | mail = IdDict.insert mailId { to = to, from = from, status = MailWaitingPickup } model.mail
                , userStatus =
                    case model.userStatus of
                        LoggedIn loggedIn ->
                            case loggedIn.adminData of
                                Just adminData ->
                                    { loggedIn
                                        | adminData =
                                            { adminData
                                                | mail =
                                                    IdDict.insert mailId
                                                        { to = to
                                                        , from = from
                                                        , status = MailWaitingPickup
                                                        , content =
                                                            -- TODO include content for admin
                                                            []
                                                        }
                                                        adminData.mail
                                            }
                                                |> Just
                                    }
                                        |> LoggedIn

                                Nothing ->
                                    model.userStatus

                        NotLoggedIn notLoggedIn_ ->
                            model.userStatus
              }
            , NoOutMsg
            )

        ServerMailStatusChanged mailId mailStatus ->
            ( { model
                | mail = IdDict.update2 mailId (\mail -> { mail | status = mailStatus }) model.mail
                , userStatus =
                    case model.userStatus of
                        LoggedIn loggedIn ->
                            case loggedIn.adminData of
                                Just adminData ->
                                    { loggedIn
                                        | adminData =
                                            { adminData
                                                | mail =
                                                    IdDict.update2 mailId (\mail -> { mail | status = mailStatus }) adminData.mail
                                            }
                                                |> Just
                                    }
                                        |> LoggedIn

                                Nothing ->
                                    model.userStatus

                        NotLoggedIn _ ->
                            model.userStatus
              }
            , NoOutMsg
            )

        ServerTeleportHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update2 trainId (Train.startTeleportingHome time) model.trains }
            , TeleportTrainHome trainId
            )

        ServerLeaveHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update2 trainId (Train.leaveHome time) model.trains }
            , TrainLeaveHome trainId
            )

        ServerWorldUpdateBroadcast diff ->
            ( { model
                | trains =
                    IdDict.toList diff
                        |> List.filterMap
                            (\( trainId, diff_ ) ->
                                case IdDict.get trainId model.trains |> Train.applyDiff diff_ of
                                    Just newTrain ->
                                        Just ( trainId, newTrain )

                                    Nothing ->
                                        Nothing
                            )
                        |> IdDict.fromList
              }
            , TrainsUpdated diff
            )

        ServerReceivedMail { mailId, from, content, deliveryTime } ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | userStatus =
                            LoggedIn
                                { loggedIn
                                    | inbox =
                                        IdDict.insert
                                            mailId
                                            { from = from
                                            , content = content
                                            , deliveryTime = deliveryTime
                                            , isViewed = False
                                            }
                                            loggedIn.inbox
                                    , adminData =
                                        case loggedIn.adminData of
                                            Just adminData ->
                                                { adminData
                                                    | mail =
                                                        IdDict.update2
                                                            mailId
                                                            (\mail ->
                                                                { mail
                                                                    | status =
                                                                        MailReceived { deliveryTime = deliveryTime }
                                                                }
                                                            )
                                                            adminData.mail
                                                }
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                }
                        , mail =
                            IdDict.update2
                                mailId
                                (\mail -> { mail | status = MailReceived { deliveryTime = deliveryTime } })
                                model.mail
                      }
                    , ReceivedMail
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        ServerViewedMail mailId userId ->
            ( { model
                | mail =
                    IdDict.update2
                        mailId
                        (\mail ->
                            { mail
                                | status =
                                    case mail.status of
                                        MailReceived data ->
                                            MailReceivedAndViewed data

                                        _ ->
                                            mail.status
                            }
                        )
                        model.mail
                , userStatus =
                    case model.userStatus of
                        LoggedIn loggedIn ->
                            if userId == loggedIn.userId then
                                { loggedIn
                                    | inbox =
                                        IdDict.update2 mailId (\mail -> { mail | isViewed = True }) loggedIn.inbox
                                    , adminData =
                                        case loggedIn.adminData of
                                            Just adminData ->
                                                { adminData
                                                    | mail =
                                                        IdDict.update2
                                                            mailId
                                                            (\mail ->
                                                                { mail
                                                                    | status =
                                                                        case mail.status of
                                                                            MailReceived data ->
                                                                                MailReceivedAndViewed data

                                                                            _ ->
                                                                                mail.status
                                                                }
                                                            )
                                                            adminData.mail
                                                }
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                }
                                    |> LoggedIn

                            else
                                model.userStatus

                        NotLoggedIn _ ->
                            model.userStatus
              }
            , NoOutMsg
            )

        ServerNewCows newCows ->
            ( { model | animals = List.Nonempty.toList newCows |> IdDict.fromList |> IdDict.union model.animals }
            , NoOutMsg
            )

        ServerChangeTool userId tool ->
            ( { model
                | cursors =
                    IdDict.update2 userId (\cursor -> { cursor | currentTool = tool }) model.cursors
              }
            , NoOutMsg
            )

        ServerGridReadOnly isGridReadOnly ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model | userStatus = LoggedIn { loggedIn | isGridReadOnly = isGridReadOnly } }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        ServerVandalismReportedToAdmin reportedBy backendReport ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | userStatus =
                            LoggedIn
                                { loggedIn
                                    | adminData =
                                        case loggedIn.adminData of
                                            Just adminData ->
                                                { adminData
                                                    | reported =
                                                        addReported reportedBy backendReport adminData.reported
                                                }
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                }
                      }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        ServerVandalismRemovedToAdmin reportedBy position ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | userStatus =
                            LoggedIn
                                { loggedIn
                                    | adminData =
                                        case loggedIn.adminData of
                                            Just adminData ->
                                                { adminData
                                                    | reported =
                                                        removeReported reportedBy position adminData.reported
                                                }
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                }
                      }
                    , NoOutMsg
                    )

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        ServerSetTrainsDisabled areTrainsDisabled ->
            ( { model | trainsDisabled = areTrainsDisabled }, NoOutMsg )


addReported :
    Id UserId
    -> BackendReport
    -> IdDict UserId (Nonempty BackendReport)
    -> IdDict UserId (Nonempty BackendReport)
addReported userId report reported =
    IdDict.update
        userId
        (\maybeList ->
            (case maybeList of
                Just nonempty ->
                    List.Nonempty.cons report nonempty

                Nothing ->
                    List.Nonempty.singleton report
            )
                |> Just
        )
        reported


removeReported userId position reported =
    IdDict.update
        userId
        (\maybeList ->
            case maybeList of
                Just nonempty ->
                    List.Nonempty.toList nonempty
                        |> List.filter (\report -> report.position /= position)
                        |> List.Nonempty.fromList

                Nothing ->
                    Nothing
        )
        reported


pickupCow : Id UserId -> Id AnimalId -> Point2d WorldUnit WorldUnit -> Effect.Time.Posix -> LocalGrid_ -> ( LocalGrid_, OutMsg )
pickupCow userId cowId position time model =
    ( { model
        | cursors =
            IdDict.update
                userId
                (\maybeCursor ->
                    case maybeCursor of
                        Just cursor ->
                            { cursor | position = position, holdingCow = Just { cowId = cowId, pickupTime = time } }
                                |> Just

                        Nothing ->
                            Cursor.defaultCursor position (Just { cowId = cowId, pickupTime = time }) |> Just
                )
                model.cursors
      }
    , OtherUserCursorMoved { userId = userId, previousPosition = IdDict.get userId model.cursors |> Maybe.map .position }
    )


dropCow : Id UserId -> Id AnimalId -> Point2d WorldUnit WorldUnit -> LocalGrid_ -> ( LocalGrid_, OutMsg )
dropCow userId cowId position model =
    ( { model
        | cursors =
            IdDict.update
                userId
                (\maybeCursor ->
                    case maybeCursor of
                        Just cursor ->
                            { cursor | position = position, holdingCow = Nothing } |> Just

                        Nothing ->
                            Cursor.defaultCursor position Nothing |> Just
                )
                model.cursors
        , animals = IdDict.update cowId (Maybe.map (\cow -> { cow | position = position })) model.animals
      }
    , OtherUserCursorMoved { userId = userId, previousPosition = IdDict.get userId model.cursors |> Maybe.map .position }
    )


moveCursor : Id UserId -> Point2d WorldUnit WorldUnit -> LocalGrid_ -> ( LocalGrid_, OutMsg )
moveCursor userId position model =
    ( { model
        | cursors =
            IdDict.update
                userId
                (\maybeCursor ->
                    (case maybeCursor of
                        Just cursor ->
                            { cursor | position = position }

                        Nothing ->
                            Cursor.defaultCursor position Nothing
                    )
                        |> Just
                )
                model.cursors
      }
    , OtherUserCursorMoved { userId = userId, previousPosition = IdDict.get userId model.cursors |> Maybe.map .position }
    )


update_ : Change -> LocalGrid_ -> ( LocalGrid_, OutMsg )
update_ msg model =
    case msg of
        LocalChange _ localChange ->
            updateLocalChange localChange model

        ServerChange serverChange ->
            updateServerChange serverChange model

        ClientChange (ViewBoundsChange bounds newCells newCows) ->
            let
                newCells2 : Dict ( Int, Int ) GridCell.Cell
                newCells2 =
                    List.map (\( coord, cell ) -> ( Coord.toTuple coord, GridCell.dataToCell coord cell )) newCells
                        |> Dict.fromList
            in
            ( { model
                | grid =
                    Grid.allCellsDict model.grid
                        |> Dict.filter (\coord _ -> Bounds.contains (Coord.tuple coord) bounds)
                        |> Dict.union newCells2
                        |> Grid.from
                , animals = IdDict.fromList newCows |> IdDict.union model.animals
                , viewBounds = bounds
              }
            , NoOutMsg
            )


config : LocalModel.Config Change LocalGrid OutMsg
config =
    { msgEqual =
        \msg0 msg1 ->
            case ( msg0, msg1 ) of
                ( ClientChange (ViewBoundsChange bounds0 _ _), ClientChange (ViewBoundsChange bounds1 _ _) ) ->
                    bounds0 == bounds1

                ( LocalChange eventId0 _, LocalChange eventId1 _ ) ->
                    eventId0 == eventId1

                _ ->
                    msg0 == msg1
    , update = \msg (LocalGrid model) -> update_ msg model |> Tuple.mapFirst LocalGrid
    }


randomAnimals : Coord CellUnit -> Random.Generator (List Animal)
randomAnimals coord =
    let
        worldCoord =
            Grid.cellAndLocalCoordToWorld ( coord, Coord.origin )
    in
    Random.weighted
        ( 0.98, [] )
        [ ( 0.005, [ Cow, Cow ] )
        , ( 0.005, [ Cow, Cow, Cow ] )
        , ( 0.005, [ Hamster ] )
        , ( 0.005, [ Sheep, Sheep ] )
        ]
        |> Random.andThen (randomAnimalsHelper worldCoord [])


randomAnimalsHelper : Coord WorldUnit -> List Animal -> List AnimalType -> Random.Generator (List Animal)
randomAnimalsHelper worldCoord output list =
    case list of
        head :: rest ->
            randomAnimal head worldCoord
                |> Random.andThen (\animal -> randomAnimalsHelper worldCoord (animal :: output) rest)

        [] ->
            Random.constant output


randomAnimal : AnimalType -> Coord WorldUnit -> Random.Generator Animal
randomAnimal animalType ( Quantity xOffset, Quantity yOffset ) =
    Random.map2
        (\x y -> { position = Point2d.unsafe { x = toFloat xOffset + x, y = toFloat yOffset + y }, animalType = animalType })
        (Random.float 0 Units.cellSize)
        (Random.float 0 Units.cellSize)


addAnimals : List (Coord CellUnit) -> { a | animals : IdDict AnimalId Animal } -> { a | animals : IdDict AnimalId Animal }
addAnimals newCells model =
    { model
        | animals =
            List.foldl
                (\newCell dict ->
                    getCowsForCell newCell
                        |> List.foldl (\cow dict2 -> IdDict.insert (IdDict.nextId dict2) cow dict2) dict
                )
                model.animals
                newCells
    }


getCowsForCell : Coord CellUnit -> List Animal
getCowsForCell newCell =
    Random.step
        (randomAnimals newCell)
        (Random.initialSeed
            (Coord.xRaw newCell * 10000 + Coord.yRaw newCell)
        )
        |> Tuple.first
        |> List.filter
            (\cow ->
                let
                    ( cellUnit, terrainUnit ) =
                        Coord.floorPoint cow.position
                            |> Grid.worldToCellAndLocalCoord
                            |> Tuple.mapSecond Terrain.localCoordToTerrain
                in
                Terrain.getTerrainValue terrainUnit cellUnit |> .terrainType |> (==) Ground
            )
