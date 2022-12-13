module LocalModel exposing (Config, LocalModel, init, localModel, unsafe, unwrap, update, updateFromBackend)

import List.Nonempty exposing (Nonempty)


type LocalModel msg model
    = LocalModel { localMsgs : List msg, localModel : model, model : model }


type alias Config msg model outMsg =
    { msgEqual : msg -> msg -> Bool
    , update : msg -> model -> ( model, outMsg )
    }


init : model -> LocalModel msg model
init model =
    LocalModel { localMsgs = [], localModel = model, model = model }


update : Config msg model outMsg -> msg -> LocalModel msg model -> ( LocalModel msg model, outMsg )
update config msg (LocalModel localModel_) =
    let
        ( newModel, outMsg ) =
            config.update msg localModel_.localModel
    in
    ( LocalModel
        { localMsgs = localModel_.localMsgs ++ [ msg ]
        , localModel = newModel
        , model = localModel_.model
        }
    , outMsg
    )


localModel : LocalModel msg model -> model
localModel (LocalModel localModel_) =
    localModel_.localModel


unwrap : LocalModel msg model -> { localMsgs : List msg, localModel : model, model : model }
unwrap (LocalModel localModel_) =
    localModel_


unsafe : { localMsgs : List msg, localModel : model, model : model } -> LocalModel msg model
unsafe =
    LocalModel


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

                            else if config.msgEqual localMsg serverMsg then
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
                newLocalMsgs
        , model = newModel
        }
