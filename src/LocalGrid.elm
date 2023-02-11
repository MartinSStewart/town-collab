module LocalGrid exposing
    ( LocalGrid
    , LocalGrid_
    , OutMsg(..)
    , addCows
    , getCowsForCell
    , incrementUndoCurrent
    , init
    , localModel
    , update
    , updateFromBackend
    )

import Bounds exposing (Bounds)
import Change exposing (Change(..), ClientChange(..), Cow, LocalChange(..), ServerChange(..), UserStatus(..))
import Color exposing (Color, Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (Cursor)
import Dict exposing (Dict)
import Effect.Time
import Grid exposing (Grid, GridData)
import GridCell
import Id exposing (CowId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import List.Nonempty exposing (Nonempty)
import LocalModel exposing (LocalModel)
import MailEditor exposing (FrontendMail, MailStatus(..))
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Random
import Terrain exposing (TerrainType(..))
import Tile exposing (Tile)
import Train exposing (Train)
import Undo
import Units exposing (CellLocalUnit, CellUnit, WorldUnit)
import User exposing (FrontendUser)


type LocalGrid
    = LocalGrid LocalGrid_


type alias LocalGrid_ =
    { grid : Grid
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , cows : IdDict CowId Cow
    , cursors : IdDict UserId Cursor
    , users : IdDict UserId FrontendUser
    , mail : IdDict MailId FrontendMail
    , trains : IdDict TrainId Train
    }


localModel : LocalModel a LocalGrid -> LocalGrid_
localModel localModel_ =
    LocalModel.localModel localModel_ |> (\(LocalGrid a) -> a)


init :
    { a
        | userStatus : UserStatus
        , grid : GridData
        , viewBounds : Bounds CellUnit
        , cows : IdDict CowId Cow
        , cursors : IdDict UserId Cursor
        , users : IdDict UserId FrontendUser
        , mail : IdDict MailId FrontendMail
        , trains : IdDict TrainId Train
    }
    -> LocalModel Change LocalGrid
init { grid, userStatus, viewBounds, cows, cursors, users, mail, trains } =
    LocalGrid
        { grid = Grid.dataToGrid grid
        , userStatus = userStatus
        , viewBounds = viewBounds
        , cows = cows
        , cursors = cursors
        , users = users
        , mail = mail
        , trains = trains
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
                        |> addCows change.newCells
                    , TilesRemoved change.removed
                    )

                NotLoggedIn ->
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

                NotLoggedIn ->
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

                NotLoggedIn ->
                    model
            , NoOutMsg
            )

        LocalAddUndo ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model | userStatus = Undo.add loggedIn |> LoggedIn }

                NotLoggedIn ->
                    model
            , NoOutMsg
            )

        InvalidChange ->
            ( model, NoOutMsg )

        PickupCow cowId position time ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    pickupCow loggedIn.userId cowId position time model

                NotLoggedIn ->
                    ( model, NoOutMsg )

        DropCow cowId position time ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    dropCow loggedIn.userId cowId position model

                NotLoggedIn ->
                    ( model, NoOutMsg )

        MoveCursor position ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    moveCursor loggedIn.userId position model

                NotLoggedIn ->
                    ( model, NoOutMsg )

        ChangeHandColor colors ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | users =
                            IdDict.update
                                loggedIn.userId
                                (Maybe.map (\user -> { user | handColor = colors }))
                                model.users
                      }
                    , HandColorOrNameChanged loggedIn.userId
                    )

                NotLoggedIn ->
                    ( model, NoOutMsg )

        ToggleRailSplit coord ->
            ( { model | grid = Grid.toggleRailSplit coord model.grid }, RailToggledBySelf coord )

        ChangeDisplayName displayName ->
            case model.userStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | users =
                            IdDict.update
                                loggedIn.userId
                                (Maybe.map (\user -> { user | name = displayName }))
                                model.users
                      }
                    , HandColorOrNameChanged loggedIn.userId
                    )

                NotLoggedIn ->
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
                            LoggedIn { loggedIn | mailDrafts = IdDict.remove submitMail.to loggedIn.mailDrafts }
                        , mail =
                            IdDict.insert mailId
                                { to = submitMail.to, from = loggedIn.userId, status = MailWaitingPickup }
                                model.mail
                      }
                    , NoOutMsg
                    )

                NotLoggedIn ->
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

                NotLoggedIn ->
                    ( model, NoOutMsg )

        TeleportHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update trainId (Maybe.map (Train.startTeleportingHome time)) model.trains }
            , TeleportTrainHome trainId
            )

        LeaveHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update trainId (Maybe.map (Train.leaveHome time)) model.trains }
            , TrainLeaveHome trainId
            )

        ViewedMail mailId ->
            ( { model
                | mail =
                    IdDict.update
                        mailId
                        (Maybe.map
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
                        )
                        model.mail
                , userStatus =
                    case model.userStatus of
                        LoggedIn loggedIn ->
                            { loggedIn
                                | inbox =
                                    IdDict.update
                                        mailId
                                        (Maybe.map
                                            (\mail -> { mail | isViewed = True })
                                        )
                                        loggedIn.inbox
                            }
                                |> LoggedIn

                        NotLoggedIn ->
                            model.userStatus
              }
            , NoOutMsg
            )

        SetAllowEmailNotifications allow ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model | userStatus = LoggedIn { loggedIn | allowEmailNotifications = allow } }

                NotLoggedIn ->
                    model
            , NoOutMsg
            )

        ChangeTool tool ->
            ( case model.userStatus of
                LoggedIn loggedIn ->
                    { model
                        | cursors =
                            IdDict.update
                                loggedIn.userId
                                (Maybe.map (\cursor -> { cursor | currentTool = tool }))
                                model.cursors
                    }

                NotLoggedIn ->
                    model
            , NoOutMsg
            )

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

                NotLoggedIn ->
                    model
            , NoOutMsg
            )


updateServerChange : ServerChange -> LocalGrid_ -> ( LocalGrid_, OutMsg )
updateServerChange serverChange model =
    case serverChange of
        ServerGridChange { gridChange, newCells, newCows } ->
            let
                model2 =
                    { model | cows = IdDict.fromList newCows |> IdDict.union model.cows }
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
                    IdDict.update
                        userId
                        (Maybe.map (\user -> { user | handColor = colors }))
                        model.users
              }
            , HandColorOrNameChanged userId
            )

        ServerUserConnected { userId, user, cowsSpawnedFromVisibleRegion } ->
            ( { model
                | users = IdDict.insert userId user model.users
                , cows = IdDict.fromList cowsSpawnedFromVisibleRegion |> IdDict.union model.cows
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
                    IdDict.update
                        userId
                        (Maybe.map (\user -> { user | name = displayName }))
                        model.users
              }
            , HandColorOrNameChanged userId
            )

        ServerSubmitMail { to, from } ->
            let
                mailId =
                    IdDict.size model.mail |> Id.fromInt
            in
            ( { model | mail = IdDict.insert mailId { to = to, from = from, status = MailWaitingPickup } model.mail }
            , NoOutMsg
            )

        ServerMailStatusChanged mailId mailStatus ->
            ( { model | mail = IdDict.update mailId (Maybe.map (\mail -> { mail | status = mailStatus })) model.mail }
            , NoOutMsg
            )

        ServerTeleportHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update trainId (Maybe.map (Train.startTeleportingHome time)) model.trains }
            , TeleportTrainHome trainId
            )

        ServerLeaveHomeTrainRequest trainId time ->
            ( { model | trains = IdDict.update trainId (Maybe.map (Train.leaveHome time)) model.trains }
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
                                }
                        , mail =
                            IdDict.update
                                mailId
                                (Maybe.map (\mail -> { mail | status = MailReceived { deliveryTime = deliveryTime } }))
                                model.mail
                      }
                    , ReceivedMail
                    )

                NotLoggedIn ->
                    ( model, NoOutMsg )

        ServerViewedMail mailId userId ->
            ( { model
                | mail =
                    IdDict.update
                        mailId
                        (Maybe.map
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
                        )
                        model.mail
                , userStatus =
                    case model.userStatus of
                        LoggedIn loggedIn ->
                            if userId == loggedIn.userId then
                                { loggedIn
                                    | inbox =
                                        IdDict.update
                                            mailId
                                            (Maybe.map
                                                (\mail -> { mail | isViewed = True })
                                            )
                                            loggedIn.inbox
                                }
                                    |> LoggedIn

                            else
                                model.userStatus

                        NotLoggedIn ->
                            model.userStatus
              }
            , NoOutMsg
            )

        ServerNewCows newCows ->
            ( { model | cows = List.Nonempty.toList newCows |> IdDict.fromList |> IdDict.union model.cows }
            , NoOutMsg
            )

        ServerChangeTool userId tool ->
            ( { model
                | cursors =
                    IdDict.update userId (Maybe.map (\cursor -> { cursor | currentTool = tool })) model.cursors
              }
            , NoOutMsg
            )


pickupCow : Id UserId -> Id CowId -> Point2d WorldUnit WorldUnit -> Effect.Time.Posix -> LocalGrid_ -> ( LocalGrid_, OutMsg )
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


dropCow : Id UserId -> Id CowId -> Point2d WorldUnit WorldUnit -> LocalGrid_ -> ( LocalGrid_, OutMsg )
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
        , cows = IdDict.update cowId (Maybe.map (\cow -> { cow | position = position })) model.cows
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
                , cows = IdDict.fromList newCows |> IdDict.union model.cows
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


randomCows : Coord CellUnit -> Random.Generator (List Cow)
randomCows coord =
    let
        worldCoord =
            Grid.cellAndLocalCoordToWorld ( coord, Coord.origin )
    in
    Random.weighted
        ( 0.98, 0 )
        [ ( 0.01, 1 )
        , ( 0.005, 2 )
        , ( 0.005, 3 )
        ]
        |> Random.andThen
            (\amount ->
                Random.list amount (randomCow worldCoord)
            )


randomCow : Coord WorldUnit -> Random.Generator Cow
randomCow ( Quantity xOffset, Quantity yOffset ) =
    Random.map2
        (\x y -> { position = Point2d.unsafe { x = toFloat xOffset + x, y = toFloat yOffset + y } })
        (Random.float 0 Units.cellSize)
        (Random.float 0 Units.cellSize)


addCows : List (Coord CellUnit) -> { a | cows : IdDict CowId Cow } -> { a | cows : IdDict CowId Cow }
addCows newCells model =
    { model
        | cows =
            List.foldl
                (\newCell dict ->
                    getCowsForCell newCell
                        |> List.foldl (\cow dict2 -> IdDict.insert (IdDict.nextId dict2) cow dict2) dict
                )
                model.cows
                newCells
    }


getCowsForCell : Coord CellUnit -> List Cow
getCowsForCell newCell =
    Random.step
        (randomCows newCell)
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
