module LocalGrid exposing
    ( Cursor
    , LocalGrid
    , LocalGrid_
    , OutMsg(..)
    , addCows
    , cowActualPosition
    , incrementUndoCurrent
    , init
    , localModel
    , update
    , updateFromBackend
    )

import Bounds exposing (Bounds)
import Change exposing (Change(..), ClientChange(..), Cow, LocalChange(..), ServerChange(..))
import Color exposing (Color)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import EverySet exposing (EverySet)
import Grid exposing (Grid, GridData)
import GridCell
import Id exposing (CowId, Id, UserId)
import IdDict exposing (IdDict)
import List.Extra as List
import List.Nonempty exposing (Nonempty)
import LocalModel exposing (LocalModel)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Random
import Terrain
import Tile exposing (Tile)
import Time
import Undo
import Units exposing (CellLocalUnit, CellUnit, WorldUnit)
import Vector2d


type LocalGrid
    = LocalGrid LocalGrid_


type alias LocalGrid_ =
    { grid : Grid
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , user : Id UserId
    , hiddenUsers : EverySet (Id UserId)
    , adminHiddenUsers : EverySet (Id UserId)
    , viewBounds : Bounds CellUnit
    , undoCurrent : Dict RawCellCoord Int
    , cows : IdDict CowId Cow
    , cursors : IdDict UserId Cursor
    }


type alias Cursor =
    { position : Point2d WorldUnit WorldUnit
    , holdingCow : Maybe { cowId : Id CowId, pickupTime : Time.Posix }
    }


localModel : LocalModel a LocalGrid -> LocalGrid_
localModel localModel_ =
    LocalModel.localModel localModel_ |> (\(LocalGrid a) -> a)


init :
    { a
        | user : Id UserId
        , grid : GridData
        , hiddenUsers : EverySet (Id UserId)
        , adminHiddenUsers : EverySet (Id UserId)
        , undoHistory : List (Dict RawCellCoord Int)
        , redoHistory : List (Dict RawCellCoord Int)
        , undoCurrent : Dict RawCellCoord Int
        , viewBounds : Bounds CellUnit
        , cows : IdDict CowId Cow
        , cursors : IdDict UserId Cursor
    }
    -> LocalModel Change LocalGrid
init { grid, undoHistory, redoHistory, undoCurrent, user, hiddenUsers, adminHiddenUsers, viewBounds, cows, cursors } =
    LocalGrid
        { grid = Grid.dataToGrid grid
        , user = user
        , undoHistory = undoHistory
        , redoHistory = redoHistory
        , hiddenUsers = hiddenUsers
        , adminHiddenUsers = adminHiddenUsers
        , viewBounds = viewBounds
        , undoCurrent = undoCurrent
        , cows = cows
        , cursors = cursors
        }
        |> LocalModel.init


cowActualPosition : Id CowId -> LocalModel Change LocalGrid -> Maybe { position : Point2d WorldUnit WorldUnit, isHeld : Bool }
cowActualPosition cowId localModel_ =
    let
        localGrid =
            localModel localModel_
    in
    case
        IdDict.toList localGrid.cursors
            |> List.find (\( _, cursor ) -> Just cowId == Maybe.map .cowId cursor.holdingCow)
    of
        Just ( _, cursor ) ->
            Just { position = Point2d.translateBy (Vector2d.unsafe { x = 0, y = 0.2 }) cursor.position, isHeld = True }

        Nothing ->
            case IdDict.get cowId localGrid.cows of
                Just cow ->
                    Just { position = cow.position, isHeld = False }

                Nothing ->
                    Nothing


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
            , primaryColor : Color
            , secondaryColor : Color
            }
        )
    | OtherUserCursorMoved { userId : Id UserId, previousPosition : Maybe (Point2d WorldUnit WorldUnit) }
    | NoOutMsg


updateLocalChange : LocalChange -> LocalGrid_ -> ( LocalGrid_, OutMsg )
updateLocalChange localChange model =
    case localChange of
        LocalGridChange gridChange ->
            let
                ( cellPosition, localPosition ) =
                    Grid.worldToCellAndLocalCoord gridChange.position

                change =
                    Grid.addChange (Grid.localChangeToChange model.user gridChange) model.grid
            in
            ( { model
                | redoHistory = []
                , grid =
                    if Bounds.contains cellPosition model.viewBounds then
                        change.grid

                    else
                        model.grid
                , undoCurrent = incrementUndoCurrent cellPosition localPosition model.undoCurrent
              }
                |> addCows change.newCells
            , TilesRemoved change.removed
            )

        LocalRedo ->
            ( case Undo.redo model of
                Just newModel ->
                    { newModel | grid = Grid.moveUndoPoint model.user newModel.undoCurrent model.grid }

                Nothing ->
                    model
            , NoOutMsg
            )

        LocalUndo ->
            ( case Undo.undo model of
                Just newModel ->
                    { newModel | grid = Grid.moveUndoPoint model.user (Dict.map (\_ a -> -a) model.undoCurrent) model.grid }

                Nothing ->
                    model
            , NoOutMsg
            )

        LocalAddUndo ->
            ( Undo.add model, NoOutMsg )

        LocalHideUser userId_ _ ->
            ( { model
                | hiddenUsers =
                    if userId_ == model.user then
                        model.hiddenUsers

                    else
                        EverySet.insert userId_ model.hiddenUsers
              }
            , NoOutMsg
            )

        LocalUnhideUser userId_ ->
            ( { model
                | hiddenUsers =
                    if userId_ == model.user then
                        model.hiddenUsers

                    else
                        EverySet.remove userId_ model.hiddenUsers
              }
            , NoOutMsg
            )

        InvalidChange ->
            ( model, NoOutMsg )

        PickupCow cowId position time ->
            pickupCow model.user cowId position time model

        DropCow cowId position time ->
            dropCow model.user cowId position model

        MoveCursor position ->
            moveCursor model.user position model


updateServerChange : ServerChange -> LocalGrid_ -> ( LocalGrid_, OutMsg )
updateServerChange serverChange model =
    case serverChange of
        ServerGridChange { gridChange, newCells } ->
            ( (if
                Bounds.contains
                    (Grid.worldToCellAndLocalCoord gridChange.position |> Tuple.first)
                    model.viewBounds
               then
                { model | grid = Grid.addChange gridChange model.grid |> .grid }

               else
                model
              )
                |> addCows newCells
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
            let
                _ =
                    Debug.log "move" position
            in
            moveCursor userId position model

        ServerUserDisconnected userId ->
            ( { model | cursors = IdDict.remove userId model.cursors }
            , NoOutMsg
            )


pickupCow : Id UserId -> Id CowId -> Point2d WorldUnit WorldUnit -> Time.Posix -> LocalGrid_ -> ( LocalGrid_, OutMsg )
pickupCow userId cowId position time model =
    ( { model
        | cursors =
            IdDict.insert
                userId
                { position = position, holdingCow = Just { cowId = cowId, pickupTime = time } }
                model.cursors
      }
    , OtherUserCursorMoved { userId = userId, previousPosition = IdDict.get userId model.cursors |> Maybe.map .position }
    )


dropCow : Id UserId -> Id CowId -> Point2d WorldUnit WorldUnit -> LocalGrid_ -> ( LocalGrid_, OutMsg )
dropCow userId cowId position model =
    ( { model
        | cursors =
            IdDict.insert userId
                { position = position
                , holdingCow = Nothing
                }
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
                            { position = position
                            , holdingCow = Nothing
                            }
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

        ClientChange (ViewBoundsChange bounds newCells) ->
            let
                newCells2 : List ( ( Int, Int ), GridCell.Cell )
                newCells2 =
                    List.map (\( coord, cell ) -> ( Coord.toTuple coord, GridCell.dataToCell coord cell )) newCells
            in
            ( { model
                | grid =
                    Grid.allCellsDict model.grid
                        |> Dict.filter (\coord _ -> Bounds.contains (Coord.tuple coord) bounds)
                        |> Dict.union (Dict.fromList newCells2)
                        |> Grid.from
                , viewBounds = bounds
              }
            , NoOutMsg
            )


config : LocalModel.Config Change LocalGrid OutMsg
config =
    { msgEqual =
        \msg0 msg1 ->
            case ( msg0, msg1 ) of
                ( ClientChange (ViewBoundsChange bounds0 _), ClientChange (ViewBoundsChange bounds1 _) ) ->
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
        ( 0.93, 0 )
        [ ( 0.05, 1 )
        , ( 0.01, 2 )
        , ( 0.01, 3 )
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
                    Random.step
                        (randomCows newCell)
                        (Random.initialSeed
                            (Coord.xRaw newCell * 10000 + Coord.yRaw newCell)
                        )
                        |> Tuple.first
                        |> List.foldl
                            (\cow dict2 ->
                                let
                                    ( cellUnit, terrainUnit ) =
                                        Coord.floorPoint cow.position
                                            |> Grid.worldToCellAndLocalCoord
                                            |> Tuple.mapSecond Terrain.localCoordToTerrain
                                in
                                if Terrain.isGroundTerrain terrainUnit cellUnit then
                                    IdDict.insert (IdDict.nextId dict2) cow dict2

                                else
                                    dict2
                            )
                            dict
                )
                model.cows
                newCells
    }
