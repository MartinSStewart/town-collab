module EndToEndTests exposing (PostmarkRequest, main, tests)

import Audio
import Backend
import Change exposing (UserStatus(..))
import Coord
import Dict
import Duration
import Effect.Lamdera
import Effect.Test exposing (Action, Config, DelayInMs, EndToEndTest, FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), PortToJs)
import Effect.WebGL.Texture exposing (Texture)
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Wheel exposing (DeltaMode(..))
import Html.Parser
import Id exposing (OneTimePasswordId, SecretId)
import Json.Decode
import Json.Encode
import Keyboard
import Local
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Postmark
import SeqDict
import Tile exposing (Category(..), TileGroup(..))
import Time
import Toolbar
import Train exposing (Status(..))
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendModel_(..), FrontendMsg, FrontendMsg_(..), Hover(..), LoadingLocalModel(..), ToBackend(..), ToFrontend, ToolButton(..), UiId(..))
import Ui
import Unsafe
import Untrusted
import Url exposing (Url)


main : Program () (Effect.Test.Model ToBackend FrontendMsg (Audio.Model Types.FrontendMsg_ FrontendModel_) ToFrontend BackendMsg BackendModel) (Effect.Test.Msg ToBackend FrontendMsg (Audio.Model Types.FrontendMsg_ FrontendModel_) ToFrontend BackendMsg BackendModel)
main =
    Effect.Test.viewerWith tests
        |> Effect.Test.addTextureWithOptions Frontend.textureOptions "/depth.png"
        |> Effect.Test.addTextureWithOptions Frontend.textureOptions "/lights.png"
        |> Effect.Test.addTextureWithOptions Frontend.textureOptions "/texture.png"
        |> Effect.Test.addTextureWithOptions Frontend.textureOptions "/train-depth.png"
        |> Effect.Test.addTextureWithOptions Frontend.textureOptions "/train-lights.png"
        |> Effect.Test.addTextureWithOptions Frontend.textureOptions "/trains.png"
        |> Effect.Test.startViewer


handleRequest :
    Texture
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> { currentRequest : HttpRequest, data : Effect.Test.Data FrontendModel BackendModel }
    -> HttpResponse
handleRequest depth lights texture trainDepth trainLights trainTexture { currentRequest } =
    if currentRequest.url == "/texture.png" && currentRequest.method == "GET" then
        Effect.Test.TextureHttpResponse
            { url = currentRequest.url
            , statusCode = 200
            , statusText = ""
            , headers = Dict.empty
            }
            texture

    else if currentRequest.url == "/depth.png" && currentRequest.method == "GET" then
        Effect.Test.TextureHttpResponse
            { url = currentRequest.url
            , statusCode = 200
            , statusText = ""
            , headers = Dict.empty
            }
            depth

    else if currentRequest.url == "/lights.png" && currentRequest.method == "GET" then
        Effect.Test.TextureHttpResponse
            { url = currentRequest.url
            , statusCode = 200
            , statusText = ""
            , headers = Dict.empty
            }
            lights

    else if currentRequest.url == "/trains.png" && currentRequest.method == "GET" then
        Effect.Test.TextureHttpResponse
            { url = currentRequest.url
            , statusCode = 200
            , statusText = ""
            , headers = Dict.empty
            }
            trainTexture

    else if currentRequest.url == "/train-depth.png" && currentRequest.method == "GET" then
        Effect.Test.TextureHttpResponse
            { url = currentRequest.url
            , statusCode = 200
            , statusText = ""
            , headers = Dict.empty
            }
            trainDepth

    else if currentRequest.url == "/train-lights.png" && currentRequest.method == "GET" then
        Effect.Test.TextureHttpResponse
            { url = currentRequest.url
            , statusCode = 200
            , statusText = ""
            , headers = Dict.empty
            }
            trainLights

    else
        let
            _ =
                Debug.log "request" currentRequest
        in
        NetworkErrorResponse


handlePorts : { currentRequest : PortToJs, data : Effect.Test.Data FrontendModel BackendModel } -> Maybe ( String, Json.Decode.Value )
handlePorts { currentRequest } =
    case currentRequest.portName of
        "user_agent_to_js" ->
            ( "user_agent_from_js"
            , Json.Encode.string "Macintosh; Intel Mac OS X 10.15; rv:108.0"
            )
                |> Just

        "martinsstewart_elm_device_pixel_ratio_to_js" ->
            ( "martinsstewart_elm_device_pixel_ratio_from_js"
            , Json.Encode.int 2
            )
                |> Just

        "get_local_storage" ->
            ( "got_local_storage"
            , Json.Encode.null
            )
                |> Just

        "audioPortToJS" ->
            Nothing

        _ ->
            let
                _ =
                    Debug.log "port request" currentRequest
            in
            Nothing


sessionId0 : Effect.Lamdera.SessionId
sessionId0 =
    Effect.Lamdera.sessionIdFromString "sessionId0"


sessionId1 : Effect.Lamdera.SessionId
sessionId1 =
    Effect.Lamdera.sessionIdFromString "sessionId1"


url : Url
url =
    Unsafe.url Env.domain


email : EmailAddress
email =
    Unsafe.emailAddress Env.adminEmail2


type alias PostmarkRequest =
    { subject : String
    , to : EmailAddress
    , htmlBody : List Html.Parser.Node
    , textBody : String
    }


decodePostmark : Json.Decode.Decoder PostmarkRequest
decodePostmark =
    Json.Decode.map4
        PostmarkRequest
        (Json.Decode.field "Subject" Json.Decode.string)
        (Json.Decode.field "To" Json.Decode.string
            |> Json.Decode.andThen
                (\to ->
                    case EmailAddress.fromString to of
                        Just emailAddress ->
                            Json.Decode.succeed emailAddress

                        Nothing ->
                            Json.Decode.fail "Invalid email address"
                )
        )
        (Json.Decode.field "HtmlBody" Json.Decode.string
            |> Json.Decode.andThen
                (\html ->
                    case Html.Parser.run html of
                        Ok nodes ->
                            Json.Decode.succeed nodes

                        Err _ ->
                            Json.Decode.fail "Failed to parse html"
                )
        )
        (Json.Decode.field "TextBody" Json.Decode.string)


isOneTimePasswordEmail :
    Effect.Test.HttpRequest
    -> Maybe { emailAddress : EmailAddress, oneTimePassword : SecretId OneTimePasswordId }
isOneTimePasswordEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            Effect.Test.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok { subject, to, textBody } ->
                        case subject of
                            "Login Email" ->
                                case String.split "\n" textBody of
                                    first :: _ ->
                                        { emailAddress = to
                                        , oneTimePassword =
                                            String.right Id.oneTimePasswordLength first |> Id.secretFromString
                                        }
                                            |> Just

                                    [] ->
                                        Nothing

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


shouldBeLoggedIn : { a | clientId : Effect.Lamdera.ClientId } -> Action toBackend frontendMsg (Audio.Model userMsg FrontendModel_) toFrontend backendMsg backendModel
shouldBeLoggedIn frontend0 =
    checkFrontend
        frontend0.clientId
        (\model ->
            case model of
                Loading loading ->
                    case loading.localModel of
                        LoadedLocalModel loadedLocalModel ->
                            case (Local.model loadedLocalModel.localModel).userStatus of
                                LoggedIn _ ->
                                    Ok ()

                                NotLoggedIn _ ->
                                    Err "Should be logged in"

                        LoadingLocalModel _ ->
                            Err "Local model not loaded"

                Loaded loaded ->
                    case (Local.model loaded.localModel).userStatus of
                        LoggedIn _ ->
                            Ok ()

                        NotLoggedIn _ ->
                            Err "Should be logged in"
        )


shouldBeLoggedOut : { a | clientId : Effect.Lamdera.ClientId } -> Action toBackend frontendMsg (Audio.Model userMsg FrontendModel_) toFrontend backendMsg backendModel
shouldBeLoggedOut frontend0 =
    checkFrontend
        frontend0.clientId
        (\model ->
            case model of
                Loading loading ->
                    case loading.localModel of
                        LoadedLocalModel loadedLocalModel ->
                            case (Local.model loadedLocalModel.localModel).userStatus of
                                LoggedIn _ ->
                                    Err "Should be logged out"

                                NotLoggedIn _ ->
                                    Ok ()

                        LoadingLocalModel _ ->
                            Err "Local model not loaded"

                Loaded loaded ->
                    case (Local.model loaded.localModel).userStatus of
                        LoggedIn _ ->
                            Err "Should be logged out"

                        NotLoggedIn _ ->
                            Ok ()
        )


typeText :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> List (Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
typeText frontend0 text =
    String.foldl
        (\char actions ->
            let
                keyEvent : Keyboard.RawKey
                keyEvent =
                    Keyboard.RawKey (String.fromChar char) ("Key" ++ String.fromChar char)
            in
            actions
                ++ [ frontend0.update 0 (Audio.UserMsg (Types.KeyDown keyEvent))
                   , frontend0.update shortWaitMs (Audio.UserMsg (Types.KeyUp keyEvent))
                   ]
        )
        []
        text


pressEnter :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List (Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
pressEnter frontend0 =
    let
        keyEvent =
            Keyboard.RawKey "Enter" ""
    in
    [ frontend0.update 100 (Audio.UserMsg (Types.KeyDown keyEvent))
    , frontend0.update shortWaitMs (Audio.UserMsg (Types.KeyUp keyEvent))
    ]


clickOnScreen :
    Effect.Test.DelayInMs
    -> Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Point2d Pixels Pixels
    -> List (Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
clickOnScreen delay frontend0 position =
    [ frontend0.update delay (Audio.UserMsg (MouseMove position))
    , frontend0.update shortWaitMs (Audio.UserMsg (MouseDown MainButton position))
    , frontend0.update shortWaitMs (Audio.UserMsg (MouseUp MainButton position))
    ]


clickOnUi :
    DelayInMs
    -> Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Types.UiId
    -> Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
clickOnUi delay frontend0 id =
    Effect.Test.andThen
        delay
        (\data ->
            case SeqDict.get frontend0.clientId data.frontends of
                Just (Audio.Model audioModel) ->
                    case audioModel.userModel of
                        Loading _ ->
                            [ Effect.Test.checkState 0 (\_ -> Err "Currently in loading state") ]

                        Loaded loaded ->
                            let
                                maybePosition : Maybe (Point2d Pixels Pixels)
                                maybePosition =
                                    case Toolbar.view loaded MapHover |> Ui.findInput id of
                                        Just (Ui.TextInputType a) ->
                                            Coord.plus a.position (Coord.divide (Coord.xy 2 2) a.size)
                                                |> Coord.toPoint2d
                                                |> Just

                                        Just (Ui.ButtonType a) ->
                                            Coord.plus a.position (Coord.divide (Coord.xy 2 2) a.size)
                                                |> Coord.toPoint2d
                                                |> Just

                                        Nothing ->
                                            Nothing
                            in
                            case maybePosition of
                                Just position ->
                                    [ frontend0.update 0 (Audio.UserMsg (Types.MouseDown MainButton position))
                                    , frontend0.update shortWaitMs (Audio.UserMsg (Types.MouseUp MainButton position))
                                    ]

                                Nothing ->
                                    [ Effect.Test.checkState 0 (\_ -> Err ("Couldn't find UI with ID: " ++ Debug.toString id)) ]

                Nothing ->
                    [ Effect.Test.checkState 0 (\_ -> Err "Couldn't find frontend") ]
        )


windowSize : { width : Int, height : Int }
windowSize =
    { width = 1000, height = 600 }


makeItDayTime :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> List (Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
makeItDayTime frontendActions =
    [ clickOnUi shortWaitMs frontendActions SettingsButton
    , clickOnUi shortWaitMs frontendActions AlwaysDayTimeOfDayButton
    , clickOnUi shortWaitMs frontendActions CloseSettings
    ]


loadPage :
    Effect.Lamdera.SessionId
    ->
        (Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> List (Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
        )
    -> Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loadPage sessionId func =
    Effect.Test.connectFrontend
        0
        sessionId
        "/"
        windowSize
        (\frontend0 ->
            pressEnter frontend0
                ++ func frontend0
        )


loadAndLogin :
    Effect.Lamdera.SessionId
    ->
        (Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> List (Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
        )
    -> Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loadAndLogin sessionId func =
    loadPage
        sessionId
        (\frontend0 ->
            [ shouldBeLoggedOut frontend0
            , clickOnUi shortWaitMs frontend0 Types.EmailAddressTextInput
            ]
                ++ typeText frontend0 Env.adminEmail2
                ++ pressEnter frontend0
                ++ [ Effect.Test.andThen
                        0
                        (\data ->
                            case List.filterMap isOneTimePasswordEmail data.httpRequests of
                                [ loginEmail ] ->
                                    [ clickOnUi shortWaitMs frontend0 Types.OneTimePasswordInput ]
                                        ++ typeText frontend0 (Id.secretToString loginEmail.oneTimePassword)
                                        ++ [ shouldBeLoggedIn frontend0 ]

                                _ ->
                                    [ Effect.Test.checkState 0 (\_ -> Err "Login email not found") ]
                        )
                   ]
                ++ func frontend0
        )


tests :
    Texture
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> List (EndToEndTest ToBackend FrontendMsg (Audio.Model Types.FrontendMsg_ FrontendModel_) ToFrontend BackendMsg BackendModel)
tests depth lights texture trainDepth trainLights trainTexture =
    let
        config : Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        config =
            { frontendApp = Frontend.app_
            , backendApp = Backend.app_ True
            , handleHttpRequest = handleRequest depth lights texture trainDepth trainLights trainTexture
            , handlePortToJs = handlePorts
            , handleFileUpload = \_ -> UnhandledFileUpload
            , handleMultipleFilesUpload = \_ -> UnhandledMultiFileUpload
            , domain = url
            }

        startTime : Time.Posix
        startTime =
            Time.millisToPosix 0
    in
    [ Effect.Test.start "Login with one time password"
        startTime
        config
        [ loadAndLogin sessionId0 (\_ -> []) ]
    , Effect.Test.start "Test NPC movement"
        startTime
        config
        [ loadAndLogin
            sessionId0
            (\frontend0 ->
                [ clickOnUi shortWaitMs frontend0 (CategoryButton Buildings) ]
                    ++ makeItDayTime frontend0
                    ++ [ clickOnUi shortWaitMs frontend0 (ToolButton (TilePlacerToolButton HouseGroup)) ]
                    ++ clickOnScreen shortWaitMs frontend0 (Point2d.pixels 300 300)
                    ++ [ clickOnUi 9000 frontend0 (CategoryButton Road)
                       , clickOnUi shortWaitMs frontend0 (ToolButton (TilePlacerToolButton SidewalkGroup))
                       ]
                    ++ List.concatMap
                        (\index ->
                            clickOnScreen shortWaitMs frontend0 (Point2d.pixels (300 + toFloat index * 20) 340)
                        )
                        (List.range 0 10)
            )
        ]
    , Effect.Test.start "Test train movement"
        startTime
        config
        [ loadAndLogin
            sessionId0
            (\frontend0 ->
                [ clickOnUi shortWaitMs frontend0 (CategoryButton Rail) ]
                    ++ makeItDayTime frontend0
                    ++ [ clickOnUi shortWaitMs frontend0 (ToolButton (TilePlacerToolButton TrainHouseGroup)) ]
                    ++ clickOnScreen shortWaitMs frontend0 (Point2d.pixels 300 300)
                    ++ [ frontend0.update 0 (Audio.UserMsg (MouseWheel { deltaY = 100, deltaMode = DeltaPixel })) ]
                    ++ clickOnScreen shortWaitMs frontend0 (Point2d.pixels 1400 300)
                    ++ [ clickOnUi shortWaitMs frontend0 (ToolButton (TilePlacerToolButton RailStraightGroup)) ]
                    ++ clickOnScreen shortWaitMs frontend0 (Point2d.pixels 340 310)
                    ++ List.concatMap
                        (\index ->
                            clickOnScreen shortWaitMs frontend0 (Point2d.pixels (340 + toFloat index * 20) 310)
                        )
                        (List.range 0 50)
                    ++ [ clickOnUi shortWaitMs frontend0 (ToolButton HandToolButton) ]
                    ++ clickOnScreen shortWaitMs frontend0 (Point2d.pixels 300 300)
                    ++ clickOnScreen 6000 frontend0 (Point2d.pixels 1400 300)
                    ++ clickOnScreen 6000 frontend0 (Point2d.pixels 1140 314)
                    ++ [ Effect.Test.checkState
                            1500
                            (\state2 ->
                                case SeqDict.values state2.backend.trains |> List.map (Train.status state2.time) of
                                    [ first, second ] ->
                                        case ( first, second ) of
                                            ( Travelling _, WaitingAtHome ) ->
                                                Ok ()

                                            ( WaitingAtHome, Travelling _ ) ->
                                                Ok ()

                                            _ ->
                                                Err "Unexpected train state"

                                    _ ->
                                        Err "Both trains not found"
                            )
                       ]
            )
        ]
    , Effect.Test.start "Can't log in for a different session"
        startTime
        config
        [ loadPage
            sessionId0
            (\frontend0 ->
                [ shouldBeLoggedOut frontend0
                , frontend0.sendToBackend 0 (SendLoginEmailRequest (Untrusted.untrust email))
                , Effect.Test.andThen
                    shortWaitMs
                    (\data ->
                        case List.filterMap isOneTimePasswordEmail data.httpRequests of
                            [ loginEmail ] ->
                                [ loadPage
                                    sessionId1
                                    (\frontend1 ->
                                        [ frontend1.sendToBackend 0 (LoginAttemptRequest loginEmail.oneTimePassword)
                                        , Effect.Test.checkState shortWaitMs (\_ -> Ok ())
                                        , shouldBeLoggedOut frontend0
                                        , shouldBeLoggedOut frontend1
                                        ]
                                    )
                                ]

                            _ ->
                                [ Effect.Test.checkState 0 (\_ -> Err "Login email not found") ]
                    )
                ]
            )
        ]
    ]


shortWaitMs : Float
shortWaitMs =
    34


checkFrontend :
    Effect.Lamdera.ClientId
    -> (userModel -> Result String ())
    -> Action toBackend frontendMsg (Audio.Model userMsg userModel) toFrontend backendMsg backendModel
checkFrontend clientId checkFunc =
    Effect.Test.checkState
        0
        (\data ->
            case SeqDict.get clientId data.frontends of
                Just (Audio.Model { userModel }) ->
                    checkFunc userModel

                Nothing ->
                    Err "Frontend 1 not found"
        )
