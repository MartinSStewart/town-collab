module AdminPage exposing (Config, Hover(..), Model, OutMsg(..), adminView, init, update)

import Array
import Change exposing (AdminData, AreTrainsAndAnimalsDisabled(..), Change, UserStatus(..))
import Color
import Coord exposing (Coord)
import Dict
import DisplayName
import Duration
import Effect.Time
import Env
import Grid
import Id exposing (Id, MailId)
import IdDict
import Keyboard
import LocalGrid exposing (LocalGrid)
import LocalModel exposing (LocalModel)
import MailEditor exposing (MailStatus(..), MailStatus2(..))
import Pixels exposing (Pixels)
import Round
import Ui exposing (BorderAndFill(..), UiEvent)


type alias Model =
    { mailPage : Int }


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Id MailId)
    | DeleteMailButton (Id MailId)


init : Model
init =
    { mailPage = 0 }


onPress event updateFunc model =
    case event of
        Ui.MousePressed _ ->
            updateFunc ()

        Ui.KeyDown _ Keyboard.Enter ->
            updateFunc ()

        _ ->
            ( model, NoOutMsg )


type OutMsg
    = OutMsgAdminChange Change.AdminChange
    | AdminPageClosed
    | NoOutMsg


type alias Config a =
    { a | localModel : LocalModel Change LocalGrid, time : Effect.Time.Posix }


update : Config a -> Hover -> UiEvent -> Model -> ( Model, OutMsg )
update config hover event model =
    case hover of
        ToggleIsGridReadOnlyButton ->
            onPress
                event
                (\() ->
                    case LocalGrid.localModel config.localModel |> .userStatus of
                        LoggedIn { isGridReadOnly } ->
                            ( model, Change.AdminSetGridReadOnly (not isGridReadOnly) |> OutMsgAdminChange )

                        NotLoggedIn _ ->
                            ( model, NoOutMsg )
                )
                model

        ToggleTrainsDisabledButton ->
            onPress
                event
                (\() ->
                    ( model
                    , Change.AdminSetTrainsDisabled
                        (case LocalGrid.localModel config.localModel |> .trainsDisabled of
                            TrainsAndAnimalsDisabled ->
                                TrainsAndAnimalsEnabled

                            TrainsAndAnimalsEnabled ->
                                TrainsAndAnimalsDisabled
                        )
                        |> OutMsgAdminChange
                    )
                )
                model

        ResetConnectionsButton ->
            onPress event (\() -> ( model, OutMsgAdminChange Change.AdminResetSessions )) model

        CloseAdminPage ->
            onPress event (\() -> ( model, AdminPageClosed )) model

        AdminMailPageButton index ->
            onPress event (\() -> ( { model | mailPage = index }, NoOutMsg )) model

        RestoreMailButton mailId ->
            onPress event (\() -> ( model, Change.AdminRestoreMail mailId |> OutMsgAdminChange )) model

        DeleteMailButton mailId ->
            onPress event (\() -> ( model, Change.AdminDeleteMail mailId config.time |> OutMsgAdminChange )) model


adminView : (Hover -> id) -> Coord Pixels -> Bool -> AdminData -> Model -> LocalGrid.LocalGrid_ -> Ui.Element id
adminView idMap windowSize isGridReadOnly adminData model localModel =
    let
        averageWorldUpdateDuration =
            if Array.isEmpty adminData.worldUpdateDurations then
                "N/A"

            else
                Array.foldl (\value total -> Duration.inMilliseconds value + total) 0 adminData.worldUpdateDurations
                    / toFloat (Array.length adminData.worldUpdateDurations)
                    |> Round.round 1

        maxWorldUpdateDuration =
            if Array.isEmpty adminData.worldUpdateDurations then
                "N/A"

            else
                Array.foldl (\value total -> max (Duration.inMilliseconds value) total) 0 adminData.worldUpdateDurations
                    |> Round.round 1
    in
    Ui.topLeft2
        { size = windowSize
        , inFront =
            [ Ui.bottomLeft
                { size = windowSize }
                (Ui.el
                    { padding = Ui.paddingXY 16 16, inFront = [], borderAndFill = NoBorderOrFill }
                    (Ui.button { id = idMap CloseAdminPage, padding = Ui.paddingXY 10 4 } (Ui.text "Close admin"))
                )
            ]
        , borderAndFill = Ui.defaultElBorderAndFill
        }
        (Ui.column
            { spacing = 8, padding = Ui.paddingXY 16 16 }
            [ Ui.row { spacing = 0, padding = Ui.noPadding }
                [ Ui.text "Admin stuff"
                , if Env.isProduction then
                    Ui.colorText Color.errorColor "(PRODUCTION)"

                  else
                    Ui.text "(dev)"
                ]
            , Ui.checkbox
                (idMap ToggleIsGridReadOnlyButton)
                isGridReadOnly
                (Grid.allCellsDict localModel.grid
                    |> Dict.size
                    |> String.fromInt
                    |> (\a -> "Read only grid (" ++ a ++ " grid cells)")
                )
            , Ui.checkbox
                (idMap ToggleTrainsDisabledButton)
                (localModel.trainsDisabled == TrainsAndAnimalsDisabled)
                ("Disable trains and animals ("
                    ++ String.fromInt (IdDict.size localModel.trains)
                    ++ " trains, "
                    ++ String.fromInt (IdDict.size localModel.animals)
                    ++ " animals)"
                )
            , Ui.text
                ("Last cache regen: "
                    ++ (case adminData.lastCacheRegeneration of
                            Just time ->
                                MailEditor.date time

                            Nothing ->
                                "Never"
                       )
                )
            , Ui.text ("World update: " ++ averageWorldUpdateDuration ++ " avg, " ++ maxWorldUpdateDuration ++ " max")
            , Ui.text "Sessions (id:count)"
            , Ui.button
                { id = idMap ResetConnectionsButton, padding = Ui.paddingXY 10 4 }
                (Ui.text "Reset connections")
            , Ui.column
                { spacing = 4, padding = Ui.noPadding }
                (List.map
                    (\data ->
                        "  "
                            ++ (case data.userId of
                                    Just userId ->
                                        Id.toInt userId |> String.fromInt

                                    Nothing ->
                                        "-"
                               )
                            ++ ":"
                            ++ String.fromInt data.connectionCount
                            |> Ui.text
                    )
                    (List.filter (\a -> a.connectionCount > 0) adminData.userSessions)
                )
            , Ui.column
                { spacing = 4, padding = Ui.noPadding }
                [ Ui.text "Backend Mail"
                , IdDict.toList adminData.mail
                    |> List.drop (model.mailPage * mailPerPage)
                    |> List.take mailPerPage
                    |> Ui.table
                        [ { header = Ui.text "From"
                          , row = \( _, mail ) -> DisplayName.nameAndId2 mail.from localModel.users |> Ui.text
                          }
                        , { header = Ui.text "To"
                          , row = \( _, mail ) -> DisplayName.nameAndId2 mail.to localModel.users |> Ui.text
                          }
                        , { header = Ui.text "Status"
                          , row =
                                \( _, mail ) ->
                                    case mail.status of
                                        MailWaitingPickup ->
                                            Ui.text "Waiting pickup"

                                        MailInTransit _ ->
                                            Ui.text "In transit"

                                        MailReceived { deliveryTime } ->
                                            "Received " ++ MailEditor.date deliveryTime |> Ui.text

                                        MailReceivedAndViewed { deliveryTime } ->
                                            "Viewed " ++ MailEditor.date deliveryTime |> Ui.text

                                        MailDeletedByAdmin deleted ->
                                            "Deleted at "
                                                ++ MailEditor.date deleted.deletedAt
                                                ++ " (was "
                                                ++ (case deleted.previousStatus of
                                                        MailWaitingPickup2 ->
                                                            "waiting pickup"

                                                        MailInTransit2 _ ->
                                                            "in transit"

                                                        MailReceived2 _ ->
                                                            "received"

                                                        MailReceivedAndViewed2 _ ->
                                                            "viewed"
                                                   )
                                                ++ ")"
                                                |> Ui.text
                          }
                        , { header = Ui.text ""
                          , row =
                                \( mailId, mail ) ->
                                    case mail.status of
                                        MailDeletedByAdmin _ ->
                                            Ui.button
                                                { id = RestoreMailButton mailId |> idMap, padding = Ui.paddingXY 6 0 }
                                                (Ui.text "Restore")

                                        _ ->
                                            Ui.button
                                                { id = DeleteMailButton mailId |> idMap, padding = Ui.paddingXY 6 0 }
                                                (Ui.text "Delete")
                          }
                        ]
                , List.range 0 (IdDict.size adminData.mail // mailPerPage)
                    |> List.map
                        (\index ->
                            Ui.selectableButton
                                { id = AdminMailPageButton index |> idMap, padding = Ui.paddingXY 8 4 }
                                (index == model.mailPage)
                                (Ui.text (String.fromInt (index + 1)))
                        )
                    |> Ui.row { spacing = 8, padding = Ui.noPadding }
                ]
            ]
        )


mailPerPage =
    20
