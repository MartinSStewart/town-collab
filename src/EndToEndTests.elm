module EndToEndTests exposing (..)

import AssocList
import Audio
import Backend
import Bytes exposing (Bytes)
import Change exposing (UserStatus(..))
import Coord
import Duration
import Effect.Http exposing (Response(..))
import Effect.Lamdera
import Effect.Test exposing (Config, HttpRequest, PortToJs)
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Html.Parser
import Id exposing (OneTimePasswordId, SecretId)
import Json.Decode
import Json.Encode
import LocalGrid
import Postmark
import Route exposing (LoginOrInviteToken(..), LoginToken, PageRoute(..), Route(..))
import Test exposing (Test)
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendModel_(..), FrontendMsg, LoadingLocalModel(..), ToBackend(..), ToFrontend)
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
            --let
            --    _ =
            --        Debug.log "file request" request
            --in
            Nothing
    , domain = url
    }


main : Program () (Effect.Test.Model (Audio.Model Types.FrontendMsg_ FrontendModel_)) Effect.Test.Msg
main =
    Effect.Test.viewer tests


handleRequest : { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> Effect.Http.Response Bytes
handleRequest { currentRequest } =
    --let
    --    _ =
    --        Debug.log "request" currentRequest
    --in
    NetworkError_


handlePorts : { currentRequest : PortToJs, pastRequests : List PortToJs } -> Maybe ( String, Json.Decode.Value )
handlePorts { currentRequest } =
    --let
    --    _ =
    --        Debug.log "port request" currentRequest
    --in
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

        "audioPortToJS" ->
            Nothing

        _ ->
            Nothing


sessionId0 =
    Effect.Lamdera.sessionIdFromString "sessionId0"


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


isInviteEmail :
    Effect.Test.HttpRequest
    -> Maybe { emailAddress : EmailAddress, loginToken : SecretId LoginToken }
isInviteEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            Effect.Test.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok { subject, to, htmlBody } ->
                        case ( subject, getRoutesFromHtml htmlBody ) of
                            ( "Town-collab invitation", [ InternalRoute { loginOrInviteToken } ] ) ->
                                case loginOrInviteToken of
                                    Just (LoginToken2 loginToken2) ->
                                        { emailAddress = to
                                        , loginToken = loginToken2
                                        }
                                            |> Just

                                    _ ->
                                        Nothing

                            _ ->
                                Nothing

                    Err _ ->
                        Nothing

            _ ->
                Nothing

    else
        Nothing


getRoutesFromHtml : List Html.Parser.Node -> List Route
getRoutesFromHtml nodes =
    List.filterMap
        (\( attributes, _ ) ->
            let
                maybeHref =
                    List.filterMap
                        (\( name, value ) ->
                            if name == "href" then
                                Just value

                            else
                                Nothing
                        )
                        attributes
                        |> List.head
            in
            maybeHref |> Maybe.andThen Url.fromString |> Maybe.andThen Route.decode
        )
        (findNodesByTag "a" nodes)


findNodesByTag : String -> List Html.Parser.Node -> List ( List Html.Parser.Attribute, List Html.Parser.Node )
findNodesByTag tagName nodes =
    List.concatMap
        (\node ->
            case node of
                Html.Parser.Element name attributes children ->
                    (if name == tagName then
                        [ ( attributes, children ) ]

                     else
                        []
                    )
                        ++ findNodesByTag tagName children

                _ ->
                    []
        )
        nodes


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

                Loaded _ ->
                    Debug.todo "Check loaded case"
        )


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

                Loaded _ ->
                    Debug.todo "Check loaded case"
        )


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
                    |> shouldBeLoggedOut frontend0
                    |> Effect.Test.sendToBackend sessionId0 frontend0.clientId (SendLoginEmailRequest (Untrusted.untrust email))
                    |> shortWait
                    |> Effect.Test.andThen
                        (\state2 ->
                            case List.filterMap isOneTimePasswordEmail state2.httpRequests of
                                [ loginEmail ] ->
                                    Effect.Test.continueWith state2
                                        |> Effect.Test.sendToBackend
                                            sessionId0
                                            frontend0.clientId
                                            (LoginAttemptRequest loginEmail.oneTimePassword)
                                        |> shortWait
                                        |> shouldBeLoggedIn frontend0

                                _ ->
                                    Effect.Test.continueWith state2
                                        |> Effect.Test.checkState (\_ -> Err "Login email not found")
                        )
            )
    , Effect.Test.start config "Can't log in for a different session"
        |> Effect.Test.connectFrontend
            sessionId0
            url
            { width = 1920, height = 1080 }
            (\( state, frontend0 ) ->
                state
                    |> shortWait
                    |> shouldBeLoggedOut frontend0
                    |> Effect.Test.sendToBackend sessionId0 frontend0.clientId (SendLoginEmailRequest (Untrusted.untrust email))
                    |> shortWait
                    |> Effect.Test.andThen
                        (\state2 ->
                            case List.filterMap isOneTimePasswordEmail state2.httpRequests of
                                [ loginEmail ] ->
                                    Effect.Test.continueWith state2
                                        |> Effect.Test.connectFrontend
                                            sessionId1
                                            url
                                            { width = 1920, height = 1080 }
                                            (\( state3, frontend1 ) ->
                                                state3
                                                    |> Effect.Test.sendToBackend
                                                        sessionId1
                                                        frontend1.clientId
                                                        (LoginAttemptRequest loginEmail.oneTimePassword)
                                                    |> shortWait
                                                    |> shouldBeLoggedOut frontend0
                                                    |> shouldBeLoggedOut frontend1
                                            )

                                _ ->
                                    Effect.Test.continueWith state2
                                        |> Effect.Test.checkState (\_ -> Err "Login email not found")
                        )
            )
    ]


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
