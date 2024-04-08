module LocalGrid exposing
    ( LocalGrid
    , OutMsg(..)
    , addNotification
    , addReported
    , ctrlOrMeta
    , currentTool
    , currentUserId
    , deleteMail
    , getAnimalsForCell
    , incrementUndoCurrent
    , init
    , keyDown
    , notificationViewportHalfSize
    , notificationViewportSize
    , placeAnimal
    , removeReported
    , restoreMail
    , setTileHotkey
    , update
    , updateAnimalMovement
    , updateFromBackend
    , updateNpcMovement
    , updateWorldUpdateDurations
    )

import Animal exposing (Animal, AnimalType(..))
import Array exposing (Array)
import AssocList
import AssocSet
import BoundingBox2d exposing (BoundingBox2d)
import BoundingBox2dExtra
import Bounds exposing (Bounds)
import Change exposing (AdminChange(..), AdminData, AreTrainsAndAnimalsDisabled(..), BackendReport, Change(..), LocalChange(..), ServerChange(..), TileHotkey, UserStatus(..))
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (Cursor)
import Dict exposing (Dict)
import Duration exposing (Duration)
import Effect.Time
import Grid exposing (Grid, GridData)
import GridCell exposing (FrontendHistory)
import Hyperlink exposing (Hyperlink)
import Id exposing (AnimalId, Id, MailId, NpcId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import LineSegment2d
import List.Nonempty exposing (Nonempty)
import Local exposing (Local)
import MailEditor exposing (FrontendMail, MailStatus(..), MailStatus2(..))
import Maybe.Extra as Maybe
import Npc exposing (Npc)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Random
import Set
import Terrain exposing (TerrainType(..))
import Tile exposing (Tile, TileGroup)
import Tool exposing (Tool(..))
import Train exposing (Train)
import Undo
import Units exposing (CellLocalUnit, CellUnit, WorldUnit)
import User exposing (FrontendUser, InviteTree)
import Vector2d exposing (Vector2d)


type alias LocalGrid =
    { grid : Grid FrontendHistory
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , previewBounds : Maybe (Bounds CellUnit)
    , animals : IdDict AnimalId Animal
    , cursors : IdDict UserId Cursor
    , users : IdDict UserId FrontendUser
    , inviteTree : InviteTree
    , mail : IdDict MailId FrontendMail
    , trains : IdDict TrainId Train
    , trainsDisabled : AreTrainsAndAnimalsDisabled
    , npcs : IdDict NpcId Npc
    }


currentUserId : { a | localModel : Local Change LocalGrid } -> Maybe (Id UserId)
currentUserId model =
    case Local.model model.localModel |> .userStatus of
        LoggedIn loggedIn ->
            Just loggedIn.userId

        NotLoggedIn _ ->
            Nothing


currentTool :
    { a | localModel : Local Change LocalGrid, pressedKeys : AssocSet.Set Keyboard.Key, currentTool : Tool }
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


ctrlOrMeta : { a | pressedKeys : AssocSet.Set Keyboard.Key } -> Bool
ctrlOrMeta model =
    keyDown Keyboard.Control model || keyDown Keyboard.Meta model


keyDown : Keyboard.Key -> { a | pressedKeys : AssocSet.Set Keyboard.Key } -> Bool
keyDown key { pressedKeys } =
    AssocSet.member key pressedKeys


init :
    { a
        | userStatus : UserStatus
        , grid : GridData
        , viewBounds : Bounds CellUnit
        , animals : IdDict AnimalId Animal
        , cursors : IdDict UserId Cursor
        , users : IdDict UserId FrontendUser
        , inviteTree : InviteTree
        , mail : IdDict MailId FrontendMail
        , trains : IdDict TrainId Train
        , trainsDisabled : AreTrainsAndAnimalsDisabled
        , npcs : IdDict NpcId Npc
    }
    -> Local Change LocalGrid
init data =
    { grid = Grid.dataToGrid data.grid
    , userStatus = data.userStatus
    , viewBounds = data.viewBounds
    , previewBounds = Nothing
    , animals = data.animals
    , cursors = data.cursors
    , users = data.users
    , inviteTree = data.inviteTree
    , mail = data.mail
    , trains = data.trains
    , trainsDisabled = data.trainsDisabled
    , npcs = data.npcs
    }
        |> Local.init


update : Change -> Local Change LocalGrid -> ( Local Change LocalGrid, OutMsg )
update change localModel_ =
    Local.update config change localModel_


updateFromBackend : Nonempty Change -> Local Change LocalGrid -> ( Local Change LocalGrid, List OutMsg )
updateFromBackend changes localModel_ =
    Local.updateFromBackend config changes localModel_


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
    | ReceivedMail
    | ExportMail (List MailEditor.Content)
    | ImportMail
    | LoggedOut
    | VisitedHyperlinkOutMsg Hyperlink


updateLocalChange : LocalChange -> LocalGrid -> ( LocalGrid, OutMsg )
updateLocalChange localChange model =
    case localChange of
        LocalGridChange gridChange ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    let
                        ( cellPosition, localPosition ) =
                            Grid.worldToCellAndLocalCoord gridChange.position

                        change =
                            Grid.addChangeFrontend (Grid.localChangeToChange loggedIn.userId gridChange) model.grid
                    in
                    ( { model
                        | userStatus =
                            { loggedIn
                                | redoHistory = []
                                , undoCurrent = incrementUndoCurrent cellPosition localPosition loggedIn.undoCurrent
                            }
                                |> LoggedIn
                        , grid =
                            if
                                List.any
                                    (Bounds.contains cellPosition)
                                    (model.viewBounds :: Maybe.toList model.previewBounds)
                            then
                                change.grid

                            else
                                model.grid
                        , animals = updateAnimalMovement gridChange model.animals
                        , npcs = updateNpcMovement gridChange model.npcs
                        , trains =
                            case Train.handleAddingTrain model.trains loggedIn.userId gridChange.change gridChange.position of
                                Just ( trainId, train ) ->
                                    IdDict.insert trainId train model.trains

                                Nothing ->
                                    model.trains
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
                                , grid = Grid.moveUndoPointFrontend loggedIn.userId newLoggedIn.undoCurrent model.grid
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
                                    Grid.moveUndoPointFrontend
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

        PickupAnimal animalId position time ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    pickupCow loggedIn.userId animalId position time model

                NotLoggedIn _ ->
                    ( model, NoOutMsg )

        DropAnimal animalId position _ ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    dropAnimal loggedIn.userId animalId position model

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
            , NoOutMsg
            )

        LeaveHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update2 trainId (Train.leaveHome time) model.trains }
            , NoOutMsg
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
                    ( updateLoggedIn model (\loggedIn -> { loggedIn | isGridReadOnly = isGridReadOnly })
                    , NoOutMsg
                    )

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

                AdminResetUpdateDuration ->
                    ( updateLoggedIn
                        model
                        (\loggedIn -> { loggedIn | adminData = Maybe.map resetUpdateDuration loggedIn.adminData })
                    , NoOutMsg
                    )

                AdminRegenerateGridCellCache regenTime ->
                    ( updateLoggedIn
                        { model | grid = Grid.regenerateGridCellCacheFrontend model.grid }
                        (\loggedIn ->
                            { loggedIn
                                | adminData =
                                    Maybe.map (\admin -> { admin | lastCacheRegeneration = Just regenTime }) loggedIn.adminData
                            }
                        )
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
            ( updateLoggedIn model (setTileHotkey tileHotkey tileGroup)
            , NoOutMsg
            )

        ShowNotifications showNotifications ->
            ( updateLoggedIn model (\loggedIn -> { loggedIn | showNotifications = showNotifications })
            , NoOutMsg
            )

        Logout ->
            logout model

        ViewBoundsChange { viewBounds, previewBounds, newCells, newCows } ->
            let
                newCells2 : Dict ( Int, Int ) (GridCell.Cell FrontendHistory)
                newCells2 =
                    List.map (\( coord, cell ) -> ( Coord.toTuple coord, GridCell.dataToCell cell )) newCells
                        |> Dict.fromList
            in
            ( { model
                | grid =
                    Grid.allCellsDict model.grid
                        |> Dict.filter
                            (\coord _ ->
                                List.any
                                    (Bounds.contains (Coord.tuple coord))
                                    (viewBounds :: Maybe.toList model.previewBounds)
                            )
                        |> Dict.union newCells2
                        |> Grid.from
                , animals = IdDict.fromList newCows |> IdDict.union model.animals
                , viewBounds = viewBounds
                , previewBounds = previewBounds
              }
            , NoOutMsg
            )

        ClearNotifications time ->
            ( updateLoggedIn model (\loggedIn -> { loggedIn | notifications = [], notificationsClearedAt = time })
            , NoOutMsg
            )

        VisitedHyperlink hyperlink ->
            ( updateLoggedIn
                model
                (\loggedIn ->
                    { loggedIn
                        | hyperlinksVisited = Set.insert (Hyperlink.toString hyperlink) loggedIn.hyperlinksVisited
                    }
                )
            , VisitedHyperlinkOutMsg hyperlink
            )


resetUpdateDuration : AdminData -> AdminData
resetUpdateDuration adminData =
    { adminData | worldUpdateDurations = Array.empty }


updateAnimalMovement :
    { a | position : Coord WorldUnit, change : Tile, time : Effect.Time.Posix }
    -> IdDict AnimalId Animal
    -> IdDict AnimalId Animal
updateAnimalMovement change animals =
    IdDict.map
        (\_ animal ->
            let
                size : Vector2d WorldUnit WorldUnit
                size =
                    (Animal.getData animal.animalType).size
                        |> Units.pixelToTileVector
                        |> Vector2d.scaleBy 0.5
                        |> Vector2d.plus (Vector2d.xy Animal.moveCollisionThreshold Animal.moveCollisionThreshold)

                position : Point2d WorldUnit WorldUnit
                position =
                    Animal.actualPositionWithoutCursor change.time animal

                changeBounds =
                    Tile.worldMovementBounds size change.change change.position

                inside =
                    List.filter (BoundingBox2d.contains position) changeBounds
            in
            if List.isEmpty inside then
                let
                    maybeIntersection : Maybe (Point2d WorldUnit WorldUnit)
                    maybeIntersection =
                        List.concatMap
                            (\bounds ->
                                BoundingBox2dExtra.lineIntersection (LineSegment2d.from position animal.endPosition) bounds
                            )
                            changeBounds
                            |> Quantity.minimumBy (Point2d.distanceFrom position)
                in
                case maybeIntersection of
                    Just intersection ->
                        { animalType = animal.animalType
                        , position = animal.position
                        , startTime = animal.startTime
                        , endPosition = intersection
                        }

                    Nothing ->
                        animal

            else
                let
                    movedTo =
                        moveOutOfCollision position changeBounds
                in
                { animalType = animal.animalType
                , position = movedTo
                , startTime = animal.startTime
                , endPosition = movedTo
                }
        )
        animals


updateNpcMovement :
    { a | position : Coord WorldUnit, change : Tile, time : Effect.Time.Posix }
    -> IdDict NpcId Npc
    -> IdDict NpcId Npc
updateNpcMovement change npcs =
    IdDict.map
        (\_ npc ->
            let
                size : Vector2d WorldUnit WorldUnit
                size =
                    Npc.size
                        |> Units.pixelToTileVector
                        |> Vector2d.scaleBy 0.5
                        |> Vector2d.plus (Vector2d.xy Npc.moveCollisionThreshold Npc.moveCollisionThreshold)

                position : Point2d WorldUnit WorldUnit
                position =
                    Npc.actualPositionWithoutCursor change.time npc

                changeBounds =
                    Tile.worldMovementBounds size change.change change.position

                inside =
                    List.filter (BoundingBox2d.contains position) changeBounds
            in
            if List.isEmpty inside then
                let
                    maybeIntersection : Maybe (Point2d WorldUnit WorldUnit)
                    maybeIntersection =
                        List.concatMap
                            (\bounds ->
                                BoundingBox2dExtra.lineIntersection (LineSegment2d.from position npc.endPosition) bounds
                            )
                            changeBounds
                            |> Quantity.minimumBy (Point2d.distanceFrom position)
                in
                case maybeIntersection of
                    Just intersection ->
                        { npc | endPosition = intersection }

                    Nothing ->
                        npc

            else
                let
                    movedTo =
                        moveOutOfCollision position changeBounds
                in
                { npc | position = movedTo, endPosition = movedTo }
        )
        npcs


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


updateLoggedIn : LocalGrid -> (Change.LoggedIn_ -> Change.LoggedIn_) -> LocalGrid
updateLoggedIn model updateFunc =
    case model.userStatus of
        LoggedIn loggedIn ->
            { model
                | userStatus =
                    updateFunc loggedIn |> LoggedIn
            }

        NotLoggedIn _ ->
            model


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

                                        MailInTransit2 _ ->
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


notificationViewportHalfSize : Coord WorldUnit
notificationViewportHalfSize =
    Coord.xy 16 16


notificationViewportSize : Coord WorldUnit
notificationViewportSize =
    Coord.scalar 2 notificationViewportHalfSize


addNotification : Coord WorldUnit -> List (Coord WorldUnit) -> List (Coord WorldUnit)
addNotification position notifications =
    let
        bounds =
            Bounds.fromCoordAndSize
                (position |> Coord.minus notificationViewportHalfSize)
                notificationViewportSize
    in
    if
        List.any
            (\coord -> Bounds.contains coord bounds)
            notifications
    then
        notifications

    else
        position :: notifications


updateServerChange : ServerChange -> LocalGrid -> ( LocalGrid, OutMsg )
updateServerChange serverChange model =
    case serverChange of
        ServerGridChange { gridChange, newAnimals } ->
            let
                model2 : LocalGrid
                model2 =
                    updateLoggedIn
                        { model | animals = IdDict.fromList newAnimals |> IdDict.union model.animals }
                        (\loggedIn ->
                            { loggedIn
                                | notifications =
                                    addNotification
                                        (Coord.plus
                                            (Coord.divide (Coord.xy 2 2) (Tile.getData gridChange.change).size)
                                            gridChange.position
                                        )
                                        loggedIn.notifications
                            }
                        )
            in
            ( if
                List.any
                    (Bounds.contains (Grid.worldToCellAndLocalCoord gridChange.position |> Tuple.first))
                    (model2.viewBounds :: Maybe.toList model.previewBounds)
              then
                { model2
                    | grid = Grid.addChangeFrontend gridChange model2.grid |> .grid
                    , animals = updateAnimalMovement gridChange model2.animals
                    , npcs = updateNpcMovement gridChange model2.npcs
                }

              else
                model2
            , NoOutMsg
            )

        ServerUndoPoint undoPoint ->
            ( { model | grid = Grid.moveUndoPointFrontend undoPoint.userId undoPoint.undoPoints model.grid }
            , NoOutMsg
            )

        ServerPickupAnimal userId cowId position time ->
            pickupCow userId cowId position time model

        ServerDropAnimal userId cowId position ->
            dropAnimal userId cowId position model

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

        ServerUserConnected { maybeLoggedIn, cowsSpawnedFromVisibleRegion } ->
            ( { model
                | users =
                    case maybeLoggedIn of
                        Just { userId, user } ->
                            IdDict.insert userId user model.users

                        Nothing ->
                            model.users
                , animals = IdDict.fromList cowsSpawnedFromVisibleRegion |> IdDict.union model.animals
              }
            , case maybeLoggedIn of
                Just { userId } ->
                    HandColorOrNameChanged userId

                Nothing ->
                    NoOutMsg
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

                        NotLoggedIn _ ->
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
            , NoOutMsg
            )

        ServerLeaveHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update2 trainId (Train.leaveHome time) model.trains }
            , NoOutMsg
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
            , NoOutMsg
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

        ServerLogout ->
            logout model

        ServerAnimalMovement newMovement ->
            ( { model
                | animals =
                    List.Nonempty.foldl
                        (\( animalId, movement ) dict ->
                            IdDict.update2
                                animalId
                                (\animal ->
                                    { animal
                                        | position = movement.position
                                        , endPosition = movement.endPosition
                                        , startTime = movement.startTime
                                    }
                                )
                                dict
                        )
                        model.animals
                        newMovement
              }
            , NoOutMsg
            )

        ServerWorldUpdateDuration duration ->
            ( updateLoggedIn
                model
                (\loggedIn ->
                    { loggedIn | adminData = Maybe.map (updateWorldUpdateDurations duration) loggedIn.adminData }
                )
            , NoOutMsg
            )

        ServerRegenerateCache regenTime ->
            ( updateLoggedIn
                { model | grid = Grid.regenerateGridCellCacheFrontend model.grid }
                (\loggedIn ->
                    { loggedIn
                        | adminData =
                            Maybe.map (\admin -> { admin | lastCacheRegeneration = Just regenTime }) loggedIn.adminData
                    }
                )
            , NoOutMsg
            )

        ServerNewNpcs npcs ->
            ( { model
                | npcs = List.Nonempty.foldl (\( npcId, npc ) state -> IdDict.insert npcId npc state) model.npcs npcs
              }
            , NoOutMsg
            )

        ServerNpcMovement newMovement ->
            ( { model
                | npcs =
                    List.Nonempty.foldl
                        (\( npcId, movement ) dict ->
                            IdDict.update2
                                npcId
                                (\npc ->
                                    { npc
                                        | position = movement.position
                                        , endPosition = movement.endPosition
                                        , startTime = movement.startTime
                                    }
                                )
                                dict
                        )
                        model.npcs
                        newMovement
              }
            , NoOutMsg
            )

        FakeServerAnimationFrame { previousTime, currentTime } ->
            case model.trainsDisabled of
                TrainsAndAnimalsDisabled ->
                    ( model, NoOutMsg )

                TrainsAndAnimalsEnabled ->
                    ( { model
                        | trains =
                            Train.moveTrains
                                currentTime
                                (Duration.from previousTime currentTime |> Quantity.min Duration.minute |> Duration.subtractFrom currentTime)
                                model.trains
                                { grid = model.grid, mail = IdDict.empty }
                      }
                    , NoOutMsg
                    )


updateWorldUpdateDurations :
    Duration
    -> { a | worldUpdateDurations : Array Duration }
    -> { a | worldUpdateDurations : Array Duration }
updateWorldUpdateDurations duration model =
    let
        newArray =
            Array.push duration model.worldUpdateDurations

        maxSize =
            1000
    in
    { model
        | worldUpdateDurations =
            if Array.length model.worldUpdateDurations > maxSize then
                newArray

            else
                Array.slice (Array.length newArray - maxSize) (Array.length newArray) newArray
    }


logout : LocalGrid -> ( LocalGrid, OutMsg )
logout model =
    case model.userStatus of
        LoggedIn loggedIn ->
            ( { model
                | userStatus = NotLoggedIn { timeOfDay = loggedIn.timeOfDay }
                , cursors = IdDict.remove loggedIn.userId model.cursors
              }
            , LoggedOut
            )

        NotLoggedIn _ ->
            ( model, NoOutMsg )


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


removeReported :
    Id UserId
    -> Coord WorldUnit
    -> IdDict UserId (Nonempty { a | position : Coord WorldUnit })
    -> IdDict UserId (Nonempty { a | position : Coord WorldUnit })
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


pickupCow : Id UserId -> Id AnimalId -> Point2d WorldUnit WorldUnit -> Effect.Time.Posix -> LocalGrid -> ( LocalGrid, OutMsg )
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


dropAnimal : Id UserId -> Id AnimalId -> Point2d WorldUnit WorldUnit -> LocalGrid -> ( LocalGrid, OutMsg )
dropAnimal userId animalId position model =
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
        , animals = IdDict.update2 animalId (placeAnimal position model.grid) model.animals
      }
    , OtherUserCursorMoved { userId = userId, previousPosition = IdDict.get userId model.cursors |> Maybe.map .position }
    )


placeAnimal : Point2d WorldUnit WorldUnit -> Grid a -> Animal -> Animal
placeAnimal position grid animal =
    let
        position2 : Point2d WorldUnit WorldUnit
        position2 =
            Grid.pointInside
                True
                (Animal.getData animal.animalType
                    |> .size
                    |> Units.pixelToTileVector
                    |> Vector2d.scaleBy 0.5
                    |> Vector2d.plus (Vector2d.xy Animal.moveCollisionThreshold Animal.moveCollisionThreshold)
                )
                position
                grid
                |> List.map .bounds
                |> moveOutOfCollision position
    in
    { animal | position = position2, endPosition = position2 }


moveOutOfCollision :
    Point2d WorldUnit WorldUnit
    -> List (BoundingBox2d WorldUnit WorldUnit)
    -> Point2d WorldUnit WorldUnit
moveOutOfCollision position bounds =
    List.map
        (\boundingBox -> BoundingBox2d.extrema boundingBox |> .maxY |> Point2d.xy (Point2d.xCoordinate position))
        bounds
        |> Quantity.maximumBy Point2d.yCoordinate
        |> Maybe.withDefault position


moveCursor : Id UserId -> Point2d WorldUnit WorldUnit -> LocalGrid -> ( LocalGrid, OutMsg )
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


update_ : Change -> LocalGrid -> ( LocalGrid, OutMsg )
update_ msg model =
    case msg of
        LocalChange _ localChange ->
            updateLocalChange localChange model

        ServerChange serverChange ->
            updateServerChange serverChange model


config : Local.Config Change LocalGrid OutMsg
config =
    { msgEqual =
        \msg0 msg1 ->
            case ( msg0, msg1 ) of
                ( LocalChange eventId0 _, LocalChange eventId1 _ ) ->
                    eventId0 == eventId1

                _ ->
                    msg0 == msg1
    , update = update_
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
        (\x y ->
            let
                position =
                    Point2d.unsafe { x = toFloat xOffset + x, y = toFloat yOffset + y }
            in
            { position = position
            , endPosition = position
            , startTime = Effect.Time.millisToPosix 0
            , animalType = animalType
            }
        )
        (Random.float 0 Units.cellSize)
        (Random.float 0 Units.cellSize)


addAnimals : List (Coord CellUnit) -> { a | animals : IdDict AnimalId Animal } -> { a | animals : IdDict AnimalId Animal }
addAnimals newCells model =
    { model
        | animals =
            List.foldl
                (\newCell dict ->
                    getAnimalsForCell newCell
                        |> List.foldl (\cow dict2 -> IdDict.insert (IdDict.nextId dict2) cow dict2) dict
                )
                model.animals
                newCells
    }


getAnimalsForCell : Coord CellUnit -> List Animal
getAnimalsForCell newCell =
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
