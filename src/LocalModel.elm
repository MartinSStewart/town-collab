module LocalModel exposing (Config, LocalModel, init, localModel, update, updateFromBackend)

import List.Nonempty exposing (Nonempty)
import Time


type LocalModel msg model
    = LocalModel { localMsgs : List ( Time.Posix, msg ), localModel : model, model : model }


type alias Config msg model outMsg =
    { msgEqual : msg -> msg -> Bool
    , update : msg -> model -> ( model, outMsg )
    }


init : model -> LocalModel msg model
init model =
    LocalModel { localMsgs = [], localModel = model, model = model }


update : Config msg model outMsg -> Time.Posix -> msg -> LocalModel msg model -> ( LocalModel msg model, outMsg )
update config time msg (LocalModel localModel_) =
    let
        ( newModel, outMsg ) =
            config.update msg localModel_.localModel
    in
    ( LocalModel
        { localMsgs = localModel_.localMsgs ++ [ ( time, msg ) ]
        , localModel = newModel
        , model = localModel_.model
        }
    , outMsg
    )


localModel : LocalModel msg model -> model
localModel (LocalModel localModel_) =
    localModel_.localModel


updateFromBackend : Config msg model outMsg -> Nonempty msg -> LocalModel msg model -> LocalModel msg model
updateFromBackend config msgs (LocalModel localModel_) =
    let
        newModel =
            List.Nonempty.foldl (\msg model -> config.update msg model |> Tuple.first) localModel_.model msgs

        newLocalMsgs =
            List.Nonempty.foldl
                (\serverMsg localMsgs_ ->
                    List.foldl
                        (\localMsg ( newList, isDone ) ->
                            if isDone then
                                ( localMsg :: newList, True )

                            else if config.msgEqual (Tuple.second localMsg) serverMsg then
                                ( newList, True )

                            else
                                ( localMsg :: newList, False )
                        )
                        ( [], False )
                        localMsgs_
                        |> Tuple.first
                        |> List.reverse
                )
                localModel_.localMsgs
                msgs
    in
    LocalModel
        { localMsgs = newLocalMsgs
        , localModel =
            List.foldl
                (\msg model -> config.update msg model |> Tuple.first)
                newModel
                (List.map Tuple.second newLocalMsgs)
        , model = newModel
        }
