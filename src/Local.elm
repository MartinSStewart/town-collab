module Local exposing (Config, Local, init, model, unsafe, unwrap, update, updateFromBackend)

import List.Nonempty exposing (Nonempty)


type Local msg model
    = Local { localMsgs : List msg, localModel : model, model : model }


type alias Config msg model outMsg =
    { msgEqual : msg -> msg -> Bool
    , update : msg -> model -> ( model, outMsg )
    }


init : model -> Local msg model
init model2 =
    Local { localMsgs = [], localModel = model2, model = model2 }


update : Config msg model outMsg -> msg -> Local msg model -> ( Local msg model, outMsg )
update config msg (Local localModel_) =
    let
        ( newModel, outMsg ) =
            config.update msg localModel_.localModel
    in
    ( Local
        { localMsgs = msg :: localModel_.localMsgs
        , localModel = newModel
        , model = localModel_.model
        }
    , outMsg
    )


model : Local msg model -> model
model (Local localModel_) =
    localModel_.localModel


unwrap : Local msg model -> { localMsgs : List msg, localModel : model, model : model }
unwrap (Local localModel_) =
    localModel_


unsafe : { localMsgs : List msg, localModel : model, model : model } -> Local msg model
unsafe =
    Local


updateFromBackend :
    Config msg model outMsg
    -> Nonempty msg
    -> Local msg model
    -> ( Local msg model, List outMsg )
updateFromBackend config msgs (Local localModel_) =
    let
        ( newModel, outMsgs ) =
            List.Nonempty.foldl
                (\msg ( model2, outMsgs2 ) -> config.update msg model2 |> Tuple.mapSecond (\a -> a :: outMsgs2))
                ( localModel_.model, [] )
                msgs

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
                (List.reverse localModel_.localMsgs)
                msgs
    in
    ( Local
        { localMsgs = List.reverse newLocalMsgs
        , localModel =
            List.foldl
                (\msg model2 -> config.update msg model2 |> Tuple.first)
                newModel
                newLocalMsgs
        , model = newModel
        }
    , List.reverse outMsgs
    )
