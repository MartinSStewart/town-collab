module EndToEndTests exposing (PostmarkRequest, main, tests)

import AssocList
import Audio
import Backend
import Change exposing (UserStatus(..))
import Coord
import Dict
import Duration
import Effect.Http exposing (Response(..))
import Effect.Lamdera
import Effect.Test exposing (Config, FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), PortToJs)
import Effect.WebGL.Texture exposing (Texture)
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Parser
import Id exposing (OneTimePasswordId, SecretId)
import Json.Decode
import Json.Encode
import Keyboard
import LocalGrid
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Postmark
import Tile exposing (Category(..), TileGroup(..))
import Toolbar
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendModel_(..), FrontendMsg, FrontendMsg_(..), Hover(..), LoadingLocalModel(..), ToBackend(..), ToFrontend, ToolButton(..), UiHover(..))
import Ui
import Unsafe
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


handleRequest : Texture -> Texture -> Texture -> Texture -> Texture -> Texture -> { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> HttpResponse
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


handlePorts : { currentRequest : PortToJs, pastRequests : List PortToJs } -> Maybe ( String, Json.Decode.Value )
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


shouldBeLoggedIn : { a | clientId : Effect.Lamdera.ClientId } -> Effect.Test.Instructions toBackend frontendMsg (Audio.Model userMsg FrontendModel_) toFrontend backendMsg backendModel -> Effect.Test.Instructions toBackend frontendMsg (Audio.Model userMsg FrontendModel_) toFrontend backendMsg backendModel
shouldBeLoggedIn frontend0 =
    checkFrontend
        frontend0.clientId
        (\model ->
            case model of
                Loading loading ->
                    case loading.localModel of
                        LoadedLocalModel loadedLocalModel ->
                            case (LocalGrid.localModel loadedLocalModel.localModel).userStatus of
                                LoggedIn _ ->
                                    Ok ()

                                NotLoggedIn _ ->
                                    Err "Should be logged in"

                        LoadingLocalModel _ ->
                            Err "Local model not loaded"

                Loaded loaded ->
                    case (LocalGrid.localModel loaded.localModel).userStatus of
                        LoggedIn _ ->
                            Ok ()

                        NotLoggedIn _ ->
                            Err "Should be logged in"
        )


shouldBeLoggedOut : { a | clientId : Effect.Lamdera.ClientId } -> Effect.Test.Instructions toBackend frontendMsg (Audio.Model userMsg FrontendModel_) toFrontend backendMsg backendModel -> Effect.Test.Instructions toBackend frontendMsg (Audio.Model userMsg FrontendModel_) toFrontend backendMsg backendModel
shouldBeLoggedOut frontend0 =
    checkFrontend
        frontend0.clientId
        (\model ->
            case model of
                Loading loading ->
                    case loading.localModel of
                        LoadedLocalModel loadedLocalModel ->
                            case (LocalGrid.localModel loadedLocalModel.localModel).userStatus of
                                LoggedIn _ ->
                                    Err "Should be logged out"

                                NotLoggedIn _ ->
                                    Ok ()

                        LoadingLocalModel _ ->
                            Err "Local model not loaded"

                Loaded loaded ->
                    case (LocalGrid.localModel loaded.localModel).userStatus of
                        LoggedIn _ ->
                            Err "Should be logged out"

                        NotLoggedIn _ ->
                            Ok ()
        )


typeText :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> String
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
typeText frontend0 text instructions =
    String.foldl
        (\char instructions2 ->
            let
                keyEvent : Keyboard.RawKey
                keyEvent =
                    Keyboard.RawKey (String.fromChar char) ("Key" ++ String.fromChar char)
            in
            frontend0.update (Audio.UserMsg (Types.KeyDown keyEvent)) instructions2
                |> shortWait
                |> frontend0.update (Audio.UserMsg (Types.KeyUp keyEvent))
        )
        instructions
        text


pressEnter :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
pressEnter frontend0 instructions =
    let
        keyEvent =
            Keyboard.RawKey "Enter" ""
    in
    frontend0.update (Audio.UserMsg (Types.KeyDown keyEvent)) instructions
        |> shortWait
        |> frontend0.update (Audio.UserMsg (Types.KeyUp keyEvent))
        |> shortWait


clickOnScreen :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Point2d Pixels Pixels
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
clickOnScreen frontend0 position instructions =
    instructions
        |> frontend0.update (Audio.UserMsg (MouseMove position))
        |> frontend0.update (Audio.UserMsg (MouseDown MainButton position))
        |> shortWait
        |> frontend0.update (Audio.UserMsg (MouseUp MainButton position))
        |> shortWait


clickOnUi :
    Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Types.UiHover
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
clickOnUi frontend0 id instructions =
    Effect.Test.andThen
        (\state ->
            case AssocList.get frontend0.clientId state.frontends of
                Just frontend ->
                    let
                        (Audio.Model audioModel) =
                            frontend.model
                    in
                    case audioModel.userModel of
                        Loading _ ->
                            Effect.Test.continueWith state
                                |> Effect.Test.checkState (\_ -> Err "Currently in loading state")

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
                                    Effect.Test.continueWith state
                                        |> frontend0.update (Audio.UserMsg (Types.MouseDown MainButton position))
                                        |> shortWait
                                        |> frontend0.update (Audio.UserMsg (Types.MouseUp MainButton position))

                                Nothing ->
                                    Effect.Test.continueWith state
                                        |> Effect.Test.checkState (\_ -> Err ("Couldn't find UI with ID: " ++ Debug.toString id))

                Nothing ->
                    Effect.Test.continueWith state |> Effect.Test.checkState (\_ -> Err "Couldn't find frontend")
        )
        instructions


windowSize =
    { width = 1000, height = 600 }


loadPage :
    Effect.Lamdera.SessionId
    ->
        (Effect.Test.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
         -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        )
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
    -> Effect.Test.Instructions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
loadPage sessionId func state =
    state
        |> Effect.Test.connectFrontend
            sessionId
            url
            windowSize
            (\( state2, frontend0 ) ->
                state2
                    |> shortWait
                    |> pressEnter frontend0
                    |> shortWait
                    |> func frontend0
            )


loadAndLogin sessionId func state =
    loadPage
        sessionId
        (\frontend0 state2 ->
            state2
                |> shouldBeLoggedOut frontend0
                |> clickOnUi frontend0 Types.EmailAddressTextInputHover
                |> typeText frontend0 Env.adminEmail2
                |> pressEnter frontend0
                |> shortWait
                |> Effect.Test.andThen
                    (\state3 ->
                        case List.filterMap isOneTimePasswordEmail state3.httpRequests of
                            [ loginEmail ] ->
                                Effect.Test.continueWith state3
                                    |> shortWait
                                    |> clickOnUi frontend0 Types.OneTimePasswordInput
                                    |> typeText frontend0 (Id.secretToString loginEmail.oneTimePassword)
                                    |> shortWait
                                    |> shouldBeLoggedIn frontend0

                            _ ->
                                Effect.Test.continueWith state3
                                    |> Effect.Test.checkState (\_ -> Err "Login email not found")
                    )
                |> func frontend0
        )
        state


tests :
    Texture
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> List (Effect.Test.Instructions ToBackend FrontendMsg (Audio.Model Types.FrontendMsg_ FrontendModel_) ToFrontend BackendMsg BackendModel)
tests depth lights texture trainDepth trainLights trainTexture =
    let
        config : Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
        config =
            { frontendApp = Frontend.app_
            , backendApp = Backend.app_ True
            , handleHttpRequest = handleRequest depth lights texture trainDepth trainLights trainTexture
            , handlePortToJs = handlePorts
            , handleFileUpload =
                \request ->
                    let
                        _ =
                            Debug.log "file request" request
                    in
                    CancelFileUpload
            , handleMultipleFilesUpload =
                \request ->
                    let
                        _ =
                            Debug.log "files request" request
                    in
                    CancelMultipleFilesUpload
            , domain = url
            }
    in
    [ Effect.Test.start config "Login with one time password"
        |> loadAndLogin sessionId0 (\_ state -> state)
    , Effect.Test.start config "Test train movement"
        |> loadAndLogin
            sessionId0
            (\frontend0 state ->
                state
                    |> clickOnUi frontend0 (CategoryButton Rail)
                    |> shortWait
                    |> clickOnUi frontend0 (ToolButtonHover (TilePlacerToolButton TrainHouseGroup))
                    |> shortWait
                    |> clickOnScreen frontend0 (Point2d.pixels 300 300)
                    |> shortWait
                    |> clickOnUi frontend0 (ToolButtonHover (TilePlacerToolButton RailStraightGroup))
                    |> shortWait
                    |> clickOnScreen frontend0 (Point2d.pixels 340 310)
                    |> (\state2 ->
                            List.foldl
                                (\index state3 ->
                                    clickOnScreen frontend0 (Point2d.pixels (340 + toFloat index * 20) 310) state3
                                )
                                state2
                                (List.range 0 12)
                       )
                    |> shortWait
                    |> clickOnUi frontend0 (ToolButtonHover HandToolButton)
                    |> shortWait
                    |> clickOnScreen frontend0 (Point2d.pixels 300 300)
                    |> (\state2 ->
                            List.foldl
                                (\_ state3 -> Effect.Test.simulateTime (Duration.seconds 0.1) state3)
                                state2
                                (List.range 1 60)
                       )
            )
    ]


shortWait :
    Effect.Test.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Effect.Test.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
shortWait =
    Effect.Test.simulateTime (Duration.milliseconds 50)


checkFrontend :
    Effect.Lamdera.ClientId
    -> (userModel -> Result String ())
    -> Effect.Test.Instructions toBackend frontendMsg (Audio.Model userMsg userModel) toFrontend backendMsg backendModel
    -> Effect.Test.Instructions toBackend frontendMsg (Audio.Model userMsg userModel) toFrontend backendMsg backendModel
checkFrontend clientId checkFunc =
    Effect.Test.checkState
        (\state4 ->
            case AssocList.get clientId state4.frontends of
                Just frontend ->
                    frontend.model
                        |> (\(Audio.Model a) -> a.userModel)
                        |> checkFunc

                Nothing ->
                    Err "Frontend 1 not found"
        )
