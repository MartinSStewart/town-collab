module LocalGrid exposing (LocalGrid, LocalGrid_, init, localModel, localModelConfig)

import Change exposing (Change(..), LocalChange(..), ServerChange(..))
import Dict exposing (Dict)
import EverySet exposing (EverySet)
import Grid exposing (Grid)
import Helper
import List.Nonempty exposing (Nonempty)
import LocalModel exposing (LocalModel)
import User exposing (UserData, UserId)


type LocalGrid
    = LocalGrid LocalGrid_


type alias LocalGrid_ =
    { grid : Grid
    , undoHistory : List (Dict ( Int, Int ) Int)
    , redoHistory : List (Dict ( Int, Int ) Int)
    , user : ( UserId, UserData )
    , otherUsers : List ( UserId, UserData )
    , hiddenUsers : EverySet UserId
    }


localModel : LocalModel a LocalGrid -> LocalGrid_
localModel localModel_ =
    LocalModel.localModel localModel_ |> (\(LocalGrid a) -> a)


init :
    Grid
    -> List (Dict ( Int, Int ) Int)
    -> List (Dict ( Int, Int ) Int)
    -> ( UserId, UserData )
    -> EverySet UserId
    -> List ( UserId, UserData )
    -> LocalGrid
init grid undoHistory redoHistory user hiddenUsers otherUsers =
    LocalGrid
        { grid = grid
        , undoHistory = undoHistory
        , redoHistory = redoHistory
        , user = user
        , hiddenUsers = hiddenUsers
        , otherUsers = otherUsers
        }


update : Change -> LocalGrid_ -> LocalGrid_
update msg model =
    let
        userId =
            Tuple.first model.user
    in
    case msg of
        LocalChange (LocalGridChange gridChange) ->
            { model
                | redoHistory = []
                , grid = Grid.addChange (Grid.localChangeToChange userId gridChange) model.grid
            }

        LocalChange LocalRedo ->
            case model.redoHistory of
                head :: rest ->
                    { model
                        | undoHistory = Grid.undoPoint userId model.grid :: model.undoHistory
                        , redoHistory = rest
                        , grid = Grid.setUndoPoints userId head model.grid
                    }

                [] ->
                    model

        LocalChange LocalUndo ->
            case model.undoHistory of
                head :: rest ->
                    { model
                        | undoHistory = rest
                        , redoHistory = Grid.undoPoint userId model.grid :: model.redoHistory
                        , grid = Grid.setUndoPoints userId head model.grid
                    }

                [] ->
                    model

        LocalChange LocalAddUndo ->
            { model
                | redoHistory = []
                , undoHistory = Grid.undoPoint userId model.grid :: model.undoHistory
            }

        LocalChange (LocalToggleUserVisibility userId_) ->
            { model
                | hiddenUsers =
                    if userId_ == userId then
                        model.hiddenUsers

                    else if EverySet.member userId_ model.hiddenUsers then
                        EverySet.remove userId_ model.hiddenUsers

                    else
                        EverySet.insert userId_ model.hiddenUsers
            }

        ServerChange (ServerGridChange gridChange) ->
            { model | grid = Grid.addChange gridChange model.grid }

        ServerChange (ServerUndoPoint undoPoint) ->
            { model | grid = Grid.setUndoPoints undoPoint.userId undoPoint.undoPoints model.grid }

        ServerChange (ServerUserNew user) ->
            { model | otherUsers = user :: model.otherUsers }


localModelConfig : LocalModel.Config Change LocalGrid
localModelConfig =
    { msgEqual = \msg0 msg1 -> msg0 == msg1
    , update = \msg (LocalGrid model) -> update msg model |> LocalGrid
    }