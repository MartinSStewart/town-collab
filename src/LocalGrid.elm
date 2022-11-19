module LocalGrid exposing (LocalGrid, LocalGrid_, incrementUndoCurrent, init, localModel, update, updateFromBackend)

import Bounds exposing (Bounds)
import Change exposing (Change(..), ClientChange(..), LocalChange(..), ServerChange(..))
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import EverySet exposing (EverySet)
import Grid exposing (Grid, GridData)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty)
import LocalModel exposing (LocalModel)
import Time
import Train exposing (Train)
import Undo
import Units exposing (CellLocalUnit, CellUnit)


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
    }
    -> LocalModel Change LocalGrid
init { grid, undoHistory, redoHistory, undoCurrent, user, hiddenUsers, adminHiddenUsers, viewBounds } =
    LocalGrid
        { grid = Grid.dataToGrid grid
        , user = user
        , undoHistory = undoHistory
        , redoHistory = redoHistory
        , hiddenUsers = hiddenUsers
        , adminHiddenUsers = adminHiddenUsers
        , viewBounds = viewBounds
        , undoCurrent = undoCurrent
        }
        |> LocalModel.init


update : Time.Posix -> Change -> LocalModel Change LocalGrid -> LocalModel Change LocalGrid
update time change localModel_ =
    LocalModel.update config time change localModel_


updateFromBackend : Nonempty Change -> LocalModel Change LocalGrid -> LocalModel Change LocalGrid
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


update_ : Change -> LocalGrid_ -> LocalGrid_
update_ msg model =
    case msg of
        LocalChange (LocalGridChange gridChange) ->
            let
                ( cellPosition, localPosition ) =
                    Grid.worldToCellAndLocalCoord gridChange.position
            in
            { model
                | redoHistory = []
                , grid =
                    if Bounds.contains cellPosition model.viewBounds then
                        Grid.addChange (Grid.localChangeToChange model.user gridChange) model.grid

                    else
                        model.grid
                , undoCurrent = incrementUndoCurrent cellPosition localPosition model.undoCurrent
            }

        LocalChange LocalRedo ->
            case Undo.redo model of
                Just newModel ->
                    { newModel | grid = Grid.moveUndoPoint model.user newModel.undoCurrent model.grid }

                Nothing ->
                    model

        LocalChange LocalUndo ->
            case Undo.undo model of
                Just newModel ->
                    { newModel | grid = Grid.moveUndoPoint model.user (Dict.map (\_ a -> -a) model.undoCurrent) model.grid }

                Nothing ->
                    model

        LocalChange LocalAddUndo ->
            Undo.add model

        LocalChange (LocalHideUser userId_ _) ->
            { model
                | hiddenUsers =
                    if userId_ == model.user then
                        model.hiddenUsers

                    else
                        EverySet.insert userId_ model.hiddenUsers
            }

        LocalChange (LocalUnhideUser userId_) ->
            { model
                | hiddenUsers =
                    if userId_ == model.user then
                        model.hiddenUsers

                    else
                        EverySet.remove userId_ model.hiddenUsers
            }

        LocalChange (LocalToggleUserVisibilityForAll hideUserId) ->
            { model | adminHiddenUsers = Coord.toggleSet hideUserId model.adminHiddenUsers }

        ServerChange (ServerGridChange gridChange) ->
            if
                Bounds.contains
                    (Grid.worldToCellAndLocalCoord gridChange.position |> Tuple.first)
                    model.viewBounds
            then
                { model | grid = Grid.addChange gridChange model.grid }

            else
                model

        ServerChange (ServerUndoPoint undoPoint) ->
            { model | grid = Grid.moveUndoPoint undoPoint.userId undoPoint.undoPoints model.grid }

        ServerChange (ServerToggleUserVisibilityForAll hideUserId) ->
            { model | adminHiddenUsers = Coord.toggleSet hideUserId model.adminHiddenUsers }

        ClientChange (ViewBoundsChange bounds newCells) ->
            { model
                | grid =
                    Grid.allCellsDict model.grid
                        |> Dict.filter (\coord _ -> Bounds.contains (Coord.tuple coord) bounds)
                        |> Dict.union (List.map (Tuple.mapFirst Coord.toTuple) newCells |> Dict.fromList)
                        |> Grid.from
                , viewBounds = bounds
            }


config : LocalModel.Config Change LocalGrid
config =
    { msgEqual =
        \msg0 msg1 ->
            case ( msg0, msg1 ) of
                ( ClientChange (ViewBoundsChange bounds0 _), ClientChange (ViewBoundsChange bounds1 _) ) ->
                    bounds0 == bounds1

                _ ->
                    msg0 == msg1
    , update = \msg (LocalGrid model) -> update_ msg model |> LocalGrid
    }
