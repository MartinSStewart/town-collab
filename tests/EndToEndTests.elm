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
import Id exposing (SecretId)
import Json.Decode
import Json.Encode
import LocalGrid
import Postmark
import Route exposing (LoginOrInviteToken(..), LoginToken, Route(..))
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


decodePostmark : Json.Decode.Decoder ( String, EmailAddress, List Html.Parser.Node )
decodePostmark =
    Json.Decode.map3 (\subject to body -> ( subject, to, body ))
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


isLoginEmail :
    Effect.Test.HttpRequest
    -> Maybe { emailAddress : EmailAddress, loginToken : SecretId LoginToken }
isLoginEmail httpRequest =
    if String.startsWith (Postmark.endpoint ++ "/email") httpRequest.url then
        case httpRequest.body of
            Effect.Test.JsonBody value ->
                case Json.Decode.decodeValue decodePostmark value of
                    Ok ( subject, to, body ) ->
                        case ( subject, getRoutesFromHtml body ) of
                            ( "Login Email", [ InternalRoute { loginOrInviteToken } ] ) ->
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


endToEndTests : List Test
endToEndTests =
    [ Effect.Test.start config "Login"
        |> Effect.Test.connectFrontend
            sessionId0
            url
            { width = 1920, height = 1080 }
            (\( state, frontend0 ) ->
                state
                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                    |> checkFrontend
                        frontend0.clientId
                        (\model ->
                            case model of
                                Loading loading ->
                                    case loading.localModel of
                                        LoadedLocalModel loadedLocalModel ->
                                            case (LocalGrid.localModel loadedLocalModel.localModel).userStatus of
                                                LoggedIn _ ->
                                                    Err "Shouldn't be logged in"

                                                NotLoggedIn _ ->
                                                    Ok ()

                                        LoadingLocalModel _ ->
                                            Err "Local model not loaded"

                                Loaded _ ->
                                    Debug.todo "Check loaded case"
                        )
                    |> Effect.Test.sendToBackend sessionId0 frontend0.clientId (SendLoginEmailRequest (Untrusted.untrust email))
                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                    |> Effect.Test.andThen
                        (\state2 ->
                            case List.filterMap isLoginEmail state2.httpRequests of
                                [ loginEmail ] ->
                                    Effect.Test.continueWith state2
                                        |> Effect.Test.connectFrontend
                                            sessionId1
                                            (Url.toString url
                                                ++ Route.encode
                                                    (Route.InternalRoute
                                                        { viewPoint = Coord.origin
                                                        , loginOrInviteToken = Just (LoginToken2 loginEmail.loginToken)
                                                        , showInbox = False
                                                        }
                                                    )
                                                |> Unsafe.url
                                            )
                                            { width = 1920, height = 1080 }
                                            (\( state3, frontend1 ) ->
                                                state3
                                                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                                                    |> checkFrontend
                                                        frontend1.clientId
                                                        (\model ->
                                                            case model of
                                                                Loading loading ->
                                                                    case loading.localModel of
                                                                        LoadedLocalModel loadedLocalModel ->
                                                                            case (LocalGrid.localModel loadedLocalModel.localModel).userStatus of
                                                                                LoggedIn loggedIn ->
                                                                                    Ok ()

                                                                                NotLoggedIn _ ->
                                                                                    Err "Not logged in"

                                                                        LoadingLocalModel _ ->
                                                                            Err "Local model not loaded"

                                                                Loaded _ ->
                                                                    Debug.todo "Check loaded case"
                                                        )
                                            )
                                        |> Effect.Test.connectFrontend
                                            sessionId1
                                            url
                                            { width = 1920, height = 1080 }
                                            (\( state5, frontend2 ) ->
                                                state5
                                                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                                                    |> checkFrontend
                                                        frontend2.clientId
                                                        (\model ->
                                                            case model of
                                                                Loading loading ->
                                                                    case loading.localModel of
                                                                        LoadedLocalModel loadedLocalModel ->
                                                                            case (LocalGrid.localModel loadedLocalModel.localModel).userStatus of
                                                                                LoggedIn loggedIn ->
                                                                                    Ok ()

                                                                                NotLoggedIn _ ->
                                                                                    Err "Not logged in"

                                                                        LoadingLocalModel _ ->
                                                                            Err "Local model not loaded"

                                                                Loaded _ ->
                                                                    Debug.todo "Check loaded case"
                                                        )
                                            )

                                _ ->
                                    Effect.Test.continueWith state2 |> Effect.Test.checkState (\_ -> Err "Login email not found")
                        )
                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                    |> checkFrontend
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
                                                    Err "Original session not logged in"

                                        LoadingLocalModel _ ->
                                            Err "Local model not loaded"

                                Loaded _ ->
                                    Debug.todo "Check loaded case"
                        )
            )
        |> Effect.Test.toTest
    ]


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


tests =
    Test.describe "End to end tests" endToEndTests
