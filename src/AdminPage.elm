module AdminPage exposing (adminView)

import Change exposing (AdminData, AreTrainsDisabled(..))
import Color
import Coord exposing (Coord)
import DisplayName
import Env
import Id
import IdDict
import LocalGrid
import MailEditor exposing (MailStatus(..))
import Pixels exposing (Pixels)
import Types exposing (UiHover(..))
import Ui exposing (BorderAndFill(..))


adminView : Coord Pixels -> Bool -> AdminData -> Int -> LocalGrid.LocalGrid_ -> Ui.Element UiHover
adminView windowSize isGridReadOnly adminData mailPage localModel =
    Ui.topLeft2
        { size = windowSize
        , inFront =
            [ Ui.bottomLeft
                { size = windowSize }
                (Ui.el
                    { padding = Ui.paddingXY 16 16, inFront = [], borderAndFill = NoBorderOrFill }
                    (Ui.button { id = CloseAdminPage, padding = Ui.paddingXY 10 4 } (Ui.text "Close admin"))
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
            , Ui.checkbox ToggleIsGridReadOnlyButton isGridReadOnly "Read only grid"
            , Ui.checkbox ToggleTrainsDisabledButton (localModel.trainsDisabled == TrainsDisabled) "Disable trains"
            , Ui.text
                ("Last cache regen: "
                    ++ (case adminData.lastCacheRegeneration of
                            Just time ->
                                MailEditor.date time

                            Nothing ->
                                "Never"
                       )
                )
            , Ui.text "Sessions (id:count)"
            , Ui.button
                { id = ResetConnectionsButton, padding = Ui.paddingXY 10 4 }
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
                    |> List.drop (mailPage * mailPerPage)
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

                                        MailInTransit id ->
                                            Ui.text "In transit"

                                        MailReceived { deliveryTime } ->
                                            "Received " ++ MailEditor.date deliveryTime |> Ui.text

                                        MailReceivedAndViewed { deliveryTime } ->
                                            "Received (viewed) " ++ MailEditor.date deliveryTime |> Ui.text
                          }
                        ]
                , List.range 0 (IdDict.size adminData.mail // mailPerPage)
                    |> List.map
                        (\index ->
                            Ui.selectableButton
                                { id = AdminMailPageButton index, padding = Ui.paddingXY 8 4 }
                                (index == mailPage)
                                (Ui.text (String.fromInt (index + 1)))
                        )
                    |> Ui.row { spacing = 8, padding = Ui.noPadding }
                ]
            ]
        )


mailPerPage =
    20
