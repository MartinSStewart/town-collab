module EndToEndTests exposing (..)

import AssocList
import Audio
import Backend
import Bounds
import Bytes exposing (Bytes)
import Coord
import Duration
import Effect.Http exposing (Response(..))
import Effect.Lamdera
import Effect.Test exposing (Config, HttpRequest, PortToJs)
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Json.Decode
import Json.Encode
import Test exposing (Test)
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend(..), ToFrontend)
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


handleRequest : { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> Effect.Http.Response Bytes
handleRequest { currentRequest } =
    let
        _ =
            Debug.log "request" currentRequest
    in
    NetworkError_


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

        "audioPortToJS" ->
            Nothing

        _ ->
            Nothing


sessionId0 =
    Effect.Lamdera.sessionIdFromString "sessionId0"


clientId0 =
    Effect.Lamdera.clientIdFromString "clientId0"


url : Url
url =
    Unsafe.url Env.domain


email : EmailAddress
email =
    Unsafe.emailAddress Env.adminEmail_


endToEndTests : List Test
endToEndTests =
    let
        toBackend =
            Effect.Test.sendToBackend sessionId0 clientId0
    in
    [ Effect.Test.start config "Login"
        |> Effect.Test.connectFrontend
            sessionId0
            url
            { width = 1920, height = 1080 }
            (\( state, _ ) ->
                state
                    |> toBackend
                        (ConnectToBackend (Bounds.fromCoordAndSize Coord.origin (Coord.xy 1 1)) Nothing)
                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                    |> toBackend (SendLoginEmailRequest (Untrusted.untrust email))
                    |> Effect.Test.simulateTime (Duration.milliseconds 50)
                    |> Effect.Test.checkState
                        (\state2 ->
                            if
                                List.any
                                    (\request ->
                                        False
                                    )
                                    state2.httpRequests
                            then
                                Ok ()

                            else
                                Err "Login email not found"
                        )
            )
        |> Effect.Test.toTest
    ]


tests =
    Test.describe "End to end tests" endToEndTests
