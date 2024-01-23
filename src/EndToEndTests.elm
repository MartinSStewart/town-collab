module EndToEndTests exposing (PostmarkRequest, main, tests)

import AssocList
import Audio
import Backend
import Bytes exposing (Bytes)
import Change exposing (UserStatus(..))
import Coord
import Duration
import Effect.Http exposing (Response(..))
import Effect.Lamdera
import Effect.Test exposing (Config, HttpRequest, HttpResponse(..), PortToJs)
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
import Toolbar
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendModel_(..), FrontendMsg, Hover(..), LoadingLocalModel(..), ToBackend(..), ToFrontend)
import Ui
import Unsafe
import Untrusted
import Url exposing (Url)


config : Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
config =
    { frontendApp = Frontend.app_
    , backendApp = Backend.app_ True
    , handleHttpRequest = handleRequest
    , handlePortToJs = handlePorts
    , handleFileRequest =
        \request ->
            let
                _ =
                    Debug.log "file request" request
            in
            Nothing
    , domain = url
    }


main : Program () (Effect.Test.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (Effect.Test.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    Effect.Test.viewer tests


handleRequest : { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> Effect.Test.HttpResponse
handleRequest { currentRequest } =
    let
        _ =
            Debug.log "request" currentRequest
    in
    NetworkErrorResponse


handlePorts : { currentRequest : PortToJs, pastRequests : List PortToJs } -> Maybe ( String, Json.Decode.Value )
handlePorts { currentRequest } =
    let
        _ =
            Debug.log "port request" currentRequest
    in
    case currentRequest.portName of
        "user_agent_to_js" ->
            ( "user_agent_from_js"
            , Json.Encode.string "Macintosh; Intel Mac OS X 10.15; rv:108.0"
            )
                |> Just

        "martinsstewart_elm_device_pixel_ratio_to_js" ->
            ( "martinsstewart_elm_device_pixel_ratio_from_js"
            , Json.Encode.int 1
            )
                |> Just

        "get_local_storage" ->
            ( "got_local_storage"
            , Json.Encode.null
            )
                |> Just

        "webgl_fix_to_js" ->
            ( "webgl_fix_from_js"
            , Json.Encode.null
            )
                |> Just

        "audioPortToJS" ->
            Nothing

        _ ->
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
                                { emailAddress = to
                                , oneTimePassword =
                                    String.right Id.oneTimePasswordLength textBody |> Id.secretFromString
                                }
                                    |> Just

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
                keyEvent =
                    Keyboard.RawKey (String.fromChar char) ("Key" ++ String.fromChar char)
            in
            frontend0.update (Audio.UserMsg (Types.KeyDown keyEvent)) instructions2
                |> frontend0.update (Audio.UserMsg (Types.KeyUp keyEvent))
        )
        instructions
        text


pressEnter frontend0 instructions =
    let
        keyEvent =
            Keyboard.RawKey "Enter" ""
    in
    frontend0.update (Audio.UserMsg (Types.KeyDown keyEvent)) instructions
        |> frontend0.update (Audio.UserMsg (Types.KeyUp keyEvent))


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
                        Loading loading ->
                            let
                                _ =
                                    Debug.log "loading" loading
                            in
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


tests : List (Effect.Test.Instructions ToBackend FrontendMsg (Audio.Model Types.FrontendMsg_ FrontendModel_) ToFrontend BackendMsg BackendModel)
tests =
    [ Effect.Test.start config "Login with one time password"
        |> Effect.Test.connectFrontend
            sessionId0
            url
            { width = 1920, height = 1080 }
            (\( state, frontend0 ) ->
                state
                    |> shortWait
                    |> pressEnter frontend0
                    |> shouldBeLoggedOut frontend0
                    |> clickOnUi frontend0 Types.EmailAddressTextInputHover
                    |> typeText frontend0 Env.adminEmail2
                    |> pressEnter frontend0
                    |> shortWait
                    |> Effect.Test.andThen
                        (\state2 ->
                            case List.filterMap isOneTimePasswordEmail state2.httpRequests of
                                [ loginEmail ] ->
                                    Effect.Test.continueWith state2
                                        |> shortWait
                                        |> clickOnUi frontend0 Types.EmailAddressTextInputHover
                                        |> typeText frontend0 (Id.secretToString loginEmail.oneTimePassword)
                                        |> shortWait
                                        |> shouldBeLoggedIn frontend0

                                _ ->
                                    Effect.Test.continueWith state2
                                        |> Effect.Test.checkState (\_ -> Err "Login email not found")
                        )
            )

    --, Effect.Test.start config "Can't log in for a different session"
    --    |> Effect.Test.connectFrontend
    --        sessionId0
    --        url
    --        { width = 1920, height = 1080 }
    --        (\( state, frontend0 ) ->
    --            state
    --                |> shortWait
    --                |> shouldBeLoggedOut frontend0
    --                |> Effect.Test.sendToBackend sessionId0 frontend0.clientId (SendLoginEmailRequest (Untrusted.untrust email))
    --                |> shortWait
    --                |> Effect.Test.andThen
    --                    (\state2 ->
    --                        case List.filterMap isOneTimePasswordEmail state2.httpRequests of
    --                            [ loginEmail ] ->
    --                                Effect.Test.continueWith state2
    --                                    |> Effect.Test.connectFrontend
    --                                        sessionId1
    --                                        url
    --                                        { width = 1920, height = 1080 }
    --                                        (\( state3, frontend1 ) ->
    --                                            state3
    --                                                |> Effect.Test.sendToBackend
    --                                                    sessionId1
    --                                                    frontend1.clientId
    --                                                    (LoginAttemptRequest loginEmail.oneTimePassword)
    --                                                |> shortWait
    --                                                |> shouldBeLoggedOut frontend0
    --                                                |> shouldBeLoggedOut frontend1
    --                                        )
    --
    --                            _ ->
    --                                Effect.Test.continueWith state2
    --                                    |> Effect.Test.checkState (\_ -> Err "Login email not found")
    --                    )
    --        )
    ]


shortWait : Effect.Test.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Effect.Test.Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
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
