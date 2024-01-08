module Effect.Test exposing
    ( start, Config, connectFrontend, FrontendApp, BackendApp, HttpRequest, HttpResponse(..), RequestedBy(..), PortToJs
    , FrontendActions, sendToBackend, simulateTime, fastForward, andThen, continueWith, Instructions, State, startTime, HttpBody(..), HttpPart(..)
    , checkState, checkBackend, toTest, toSnapshots
    , fakeNavigationKey, viewer, Msg, Model, viewerWith, ViewerWith, startViewer, addBytesFile, addTexture, addTextureWithOptions
    )

{-|


## Setting up end to end tests

@docs start, Config, connectFrontend, FrontendApp, BackendApp, HttpRequest, HttpResponse, RequestedBy, PortToJs


## Control the tests

@docs FrontendActions, sendToBackend, simulateTime, fastForward, andThen, continueWith, Instructions, State, startTime, HttpBody, HttpPart


## Check the current state

@docs checkState, checkBackend, toTest, toSnapshots


## Test viewer

Sometimes it's hard to tell what's going on in an end to end test. One way to make this easier to use the `viewer` function. It's like a test runner for your browser that also lets you see the frontend of an app as simulated inputs are being triggered.

@docs fakeNavigationKey, viewer, Msg, Model, viewerWith, ViewerWith, startViewer, addBytesFile, addTexture, addTextureWithOptions

-}

import AssocList as Dict exposing (Dict)
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Browser.Navigation
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Dict as RegularDict
import Duration exposing (Duration)
import Effect.Browser.Dom exposing (HtmlId)
import Effect.Browser.Navigation
import Effect.Command exposing (BackendOnly, Command, FrontendOnly)
import Effect.Http exposing (Body)
import Effect.Internal exposing (Command(..), File, NavigationKey(..), Task(..))
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Snapshot exposing (Snapshot)
import Effect.Subscription exposing (Subscription)
import Effect.WebGL.Texture
import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Json.Encode
import List.Nonempty exposing (Nonempty)
import Process
import Quantity
import Task
import Test exposing (Test)
import Test.Html.Event
import Test.Html.Internal.ElmHtml.ToString
import Test.Html.Internal.Inert
import Test.Html.Query
import Test.Html.Selector
import Test.Runner
import Time
import Url exposing (Url)
import WebGL.Texture
import WebGLFix.Texture


{-| Configure the end to end test before starting it

    import Backend
    import Effect.Test
    import Frontend
    import Test exposing (Test)

    config =
        { frontendApp = Frontend.appFunctions
        , backendApp = Backend.appFunctions
        , handleHttpRequest = always NetworkError_
        , handlePortToJs = always Nothing
        , handleFileRequest = always Nothing
        , domain = unsafeUrl "https://my-app.lamdera.app"
        }

    test : Test
    test =
        Effect.Test.start "myButton is clickable"
            |> Effect.Test.connectFrontend
                sessionId0
                myDomain
                { width = 1920, height = 1080 }
                (\( state, frontendActions ) ->
                    state
                        |> frontendActions.clickButton { htmlId = "myButton" }
                )
            |> Effect.Test.toTest

-}
type alias Config toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { frontendApp : FrontendApp toBackend frontendMsg frontendModel toFrontend
    , backendApp : BackendApp toBackend toFrontend backendMsg backendModel
    , handleHttpRequest : { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> HttpResponse
    , handlePortToJs : { currentRequest : PortToJs, pastRequests : List PortToJs } -> Maybe ( String, Json.Decode.Value )
    , handleFileRequest : { mimeTypes : List String } -> Maybe { name : String, mimeType : String, content : String, lastModified : Time.Posix }
    , domain : Url
    }


{-| -}
type alias State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { testName : String
    , frontendApp : FrontendApp toBackend frontendMsg frontendModel toFrontend
    , backendApp : BackendApp toBackend toFrontend backendMsg backendModel
    , backend : backendModel
    , pendingEffects : Command BackendOnly toFrontend backendMsg
    , frontends : Dict ClientId (FrontendState toBackend frontendMsg frontendModel toFrontend)
    , counter : Int
    , elapsedTime : Duration
    , toBackend : List ( SessionId, ClientId, toBackend )
    , timers : Dict Duration { msg : Time.Posix -> backendMsg, startTime : Time.Posix }
    , testErrors : List TestError
    , httpRequests : List HttpRequest
    , handleHttpRequest : { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> HttpResponse
    , handlePortToJs :
        { currentRequest : PortToJs, pastRequests : List PortToJs }
        -> Maybe ( String, Json.Decode.Value )
    , portRequests : List PortToJs
    , handleFileRequest : { mimeTypes : List String } -> Maybe Effect.Internal.File
    , domain : Url
    , snapshots : List { name : String, body : List (Html frontendMsg), width : Int, height : Int }
    }


{-| -}
type alias PortToJs =
    { clientId : ClientId, portName : String, value : Json.Encode.Value }


{-| -}
type alias HttpRequest =
    { requestedBy : RequestedBy
    , method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    }


{-| The response for an http request.
Note that if the http request was expecting one form of data (for example json) and the response contains a different type of data (for example a String) then the data will automatically be converted.
The exception to this is Texture. If the request is expecting a Texture (this will only happen with `Effect.WebGL.Texture.load` and `Effect.WebGL.Texture.loadWith`) then the response has to contain a Texture if you want the request to succeed.
In other words, sending the Bytes that represent that texture won't work.
-}
type HttpResponse
    = BadUrlResponse String
    | TimeoutResponse
    | NetworkErrorResponse
    | BadStatusResponse Effect.Http.Metadata String
    | BytesHttpResponse Effect.Http.Metadata Bytes
    | StringHttpResponse Effect.Http.Metadata String
    | JsonHttpResponse Effect.Http.Metadata Json.Encode.Value
    | TextureHttpResponse Effect.Http.Metadata Effect.WebGL.Texture.Texture


{-| Who made this http request?
-}
type RequestedBy
    = RequestedByFrontend ClientId
    | RequestedByBackend


{-| Only use this for tests!
-}
fakeNavigationKey : Effect.Browser.Navigation.Key
fakeNavigationKey =
    Effect.Browser.Navigation.fromInternalKey Effect.Internal.MockNavigationKey


httpBodyFromInternal : Effect.Internal.HttpBody -> HttpBody
httpBodyFromInternal body =
    case body of
        Effect.Internal.EmptyBody ->
            EmptyBody

        Effect.Internal.StringBody record ->
            StringBody record

        Effect.Internal.JsonBody value ->
            JsonBody value

        Effect.Internal.MultipartBody httpParts ->
            List.map httpPartFromInternal httpParts |> MultipartBody

        Effect.Internal.BytesBody string bytes ->
            BytesBody string bytes

        Effect.Internal.FileBody file ->
            FileBody file


{-| -}
type HttpBody
    = EmptyBody
    | StringBody
        { contentType : String
        , content : String
        }
    | JsonBody Json.Encode.Value
    | MultipartBody (List HttpPart)
    | BytesBody String Bytes
    | FileBody File


httpPartFromInternal part =
    case part of
        Effect.Internal.StringPart a b ->
            StringPart a b

        Effect.Internal.FilePart string file ->
            FilePart string file

        Effect.Internal.BytesPart key mimeType bytes ->
            BytesPart { key = key, mimeType = mimeType, content = bytes }


type TestError
    = CustomError String
    | ClientIdNotFound ClientId
    | ViewTestError String
    | InvalidUrl String


{-| -}
type HttpPart
    = StringPart String String
    | FilePart String File
    | BytesPart { key : String, mimeType : String, content : Bytes }


{-| -}
type Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    = NextStep String (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    | AndThen (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    | Start (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)


{-| -}
checkState :
    (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Result String ())
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkState checkFunc =
    NextStep
        "Check state"
        (\state ->
            case checkFunc state of
                Ok () ->
                    state

                Err error ->
                    addTestError (CustomError error) state
        )


{-| -}
checkBackend :
    (backendModel -> Result String ())
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkBackend checkFunc =
    NextStep
        "Check backend"
        (\state ->
            case checkFunc state.backend of
                Ok () ->
                    state

                Err error ->
                    addTestError (CustomError error) state
        )


{-| -}
checkFrontend :
    ClientId
    -> (frontendModel -> Result String ())
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkFrontend clientId checkFunc =
    NextStep
        "Check frontend"
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case checkFunc frontend.model of
                        Ok () ->
                            state

                        Err error ->
                            addTestError (CustomError error) state

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )


addTestError :
    TestError
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
addTestError error state =
    { state | testErrors = state.testErrors ++ [ error ] }


checkView :
    ClientId
    -> (Test.Html.Query.Single frontendMsg -> Expectation)
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
checkView clientId query =
    NextStep
        "Check view"
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case
                        state.frontendApp.view frontend.model
                            |> .body
                            |> Html.div []
                            |> Test.Html.Query.fromHtml
                            |> query
                            |> Test.Runner.getFailureReason
                    of
                        Just { description } ->
                            addTestError (ViewTestError description) state

                        Nothing ->
                            state

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )


frontendUpdate :
    ClientId
    -> frontendMsg
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
frontendUpdate clientId msg =
    let
        msgString =
            Debug.toString msg
    in
    NextStep
        ("Frontend update: "
            ++ (if String.length msgString < 100 then
                    msgString

                else
                    String.left 97 msgString ++ "..."
               )
        )
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( newModel, effects ) =
                            state.frontendApp.update msg frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert
                                clientId
                                { frontend
                                    | model = newModel
                                    , pendingEffects = Effect.Command.batch [ effects, frontend.pendingEffects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )


testErrorToString : TestError -> String
testErrorToString error =
    case error of
        CustomError text_ ->
            text_

        ClientIdNotFound clientId ->
            "Client Id " ++ Effect.Lamdera.clientIdToString clientId ++ " not found"

        ViewTestError string ->
            if String.length string > 100 then
                String.left 100 string ++ "..."

            else
                string

        InvalidUrl string ->
            string ++ " is not a valid url"


{-| -}
toTest : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Test
toTest instructions =
    let
        state =
            instructionsToState instructions
    in
    Test.test state.testName <|
        \() ->
            case state.testErrors of
                firstError :: _ ->
                    testErrorToString firstError |> Expect.fail

                [] ->
                    let
                        duplicates =
                            gatherEqualsBy .name state.snapshots
                                |> List.filterMap
                                    (\( first, rest ) ->
                                        if List.isEmpty rest then
                                            Nothing

                                        else
                                            Just ( first.name, List.length rest + 1 )
                                    )
                    in
                    case duplicates of
                        [] ->
                            Expect.pass

                        ( name, count ) :: [] ->
                            "A snapshot named \""
                                ++ name
                                ++ "\" appears "
                                ++ String.fromInt count
                                ++ " times. Make sure snapshot names are unique!"
                                |> Expect.fail

                        rest ->
                            "These snapshot names appear multiple times:"
                                ++ String.concat
                                    (List.map
                                        (\( name, count ) -> "\n" ++ name ++ " (" ++ String.fromInt count ++ " times)")
                                        rest
                                    )
                                ++ " Make sure snapshot names are unique!"
                                |> Expect.fail


{-| Copied from elm-community/list-extra

Group equal elements together. A function is applied to each element of the list
and then the equality check is performed against the results of that function evaluation.
Elements will be grouped in the same order as they appear in the original list. The
same applies to elements within each group.
gatherEqualsBy .age [{age=25},{age=23},{age=25}]
--> [({age=25},[{age=25}]),({age=23},[])]

-}
gatherEqualsBy : (a -> b) -> List a -> List ( a, List a )
gatherEqualsBy extract list =
    gatherWith (\a b -> extract a == extract b) list


{-| Copied from elm-community/list-extra

Group equal elements together using a custom equality function. Elements will be
grouped in the same order as they appear in the original list. The same applies to
elements within each group.
gatherWith (==) [1,2,1,3,2]
--> [(1,[1]),(2,[2]),(3,[])]

-}
gatherWith : (a -> a -> Bool) -> List a -> List ( a, List a )
gatherWith testFn list =
    let
        helper : List a -> List ( a, List a ) -> List ( a, List a )
        helper scattered gathered =
            case scattered of
                [] ->
                    List.reverse gathered

                toGather :: population ->
                    let
                        ( gathering, remaining ) =
                            List.partition (testFn toGather) population
                    in
                    helper remaining (( toGather, gathering ) :: gathered)
    in
    helper list []


{-| Get all snapshots from a test.
This can be used with Effect.Snapshot.uploadSnapshots to perform visual regression testing.
-}
toSnapshots :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> List (Snapshot frontendMsg)
toSnapshots instructions =
    let
        state =
            instructionsToState instructions
    in
    state
        |> .snapshots
        |> List.map
            (\{ name, body, width, height } ->
                { name = state.testName ++ ": " ++ name
                , body = body
                , widths = List.Nonempty.fromElement width
                , minimumHeight = Just height
                }
            )


flatten :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Nonempty ( String, State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel )
flatten inProgress =
    List.Nonempty.reverse (flattenHelper inProgress)


flattenHelper :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Nonempty ( String, State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel )
flattenHelper inProgress =
    case inProgress of
        NextStep name stepFunc inProgress_ ->
            let
                list =
                    flattenHelper inProgress_

                previousState =
                    List.Nonempty.head list |> Tuple.second
            in
            List.Nonempty.cons ( name, stepFunc previousState ) list

        AndThen andThenFunc inProgress_ ->
            let
                list =
                    flattenHelper inProgress_

                previousState =
                    List.Nonempty.head list |> Tuple.second
            in
            List.Nonempty.append (flattenHelper (andThenFunc previousState)) list

        Start state ->
            List.Nonempty.fromElement ( "Start", state )


instructionsToState :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
instructionsToState inProgress =
    case inProgress of
        NextStep _ stateFunc inProgress_ ->
            instructionsToState inProgress_ |> stateFunc

        AndThen stateFunc inProgress_ ->
            instructionsToState inProgress_ |> stateFunc |> instructionsToState

        Start state ->
            state


type alias FrontendState toBackend frontendMsg frontendModel toFrontend =
    { model : frontendModel
    , sessionId : SessionId
    , pendingEffects : Command FrontendOnly toBackend frontendMsg
    , toFrontend : List toFrontend
    , clipboard : String
    , timers : Dict Duration { msg : Time.Posix -> frontendMsg, startTime : Time.Posix }
    , url : Url
    , windowSize : { width : Int, height : Int }
    }


{-| -}
startTime : Time.Posix
startTime =
    Time.millisToPosix 0


{-| -}
type alias FrontendApp toBackend frontendMsg frontendModel toFrontend =
    { init : Url -> Effect.Browser.Navigation.Key -> ( frontendModel, Command FrontendOnly toBackend frontendMsg )
    , onUrlRequest : UrlRequest -> frontendMsg
    , onUrlChange : Url -> frontendMsg
    , update : frontendMsg -> frontendModel -> ( frontendModel, Command FrontendOnly toBackend frontendMsg )
    , updateFromBackend : toFrontend -> frontendModel -> ( frontendModel, Command FrontendOnly toBackend frontendMsg )
    , view : frontendModel -> Browser.Document frontendMsg
    , subscriptions : frontendModel -> Subscription FrontendOnly frontendMsg
    }


{-| -}
type alias BackendApp toBackend toFrontend backendMsg backendModel =
    { init : ( backendModel, Command BackendOnly toFrontend backendMsg )
    , update : backendMsg -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
    , subscriptions : backendModel -> Subscription BackendOnly backendMsg
    }


{-| FrontendActions contains the possible functions we can call on the client we just connected.

    import Effect.Test
    import Test exposing (Test)

    testApp =
        Effect.Test.testApp
            Frontend.appFunctions
            Backend.appFunctions
            (always NetworkError_)
            (always Nothing)
            (always Nothing)
            (unsafeUrl "https://my-app.lamdera.app")

    test : Test
    test =
        testApp "myButton is clickable"
            |> Effect.Test.connectFrontend
                sessionId0
                myDomain
                { width = 1920, height = 1080 }
                (\( state, frontendActions ) ->
                    -- frontendActions is a record we can use on this specific frontend we just connected
                    state
                        |> frontendActions.clickButton { htmlId = "myButton" }
                )
            |> Effect.Test.toTest

-}
type alias FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { clientId : ClientId
    , keyDownEvent :
        HtmlId
        -> { keyCode : Int }
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickButton :
        HtmlId
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , inputText :
        HtmlId
        -> String
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , clickLink :
        { href : String }
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , checkView :
        (Test.Html.Query.Single frontendMsg -> Expectation)
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , update :
        frontendMsg
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , snapshotView :
        { name : String }
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    }


{-| Setup a test.

    import Backend
    import Effect.Test
    import Frontend
    import Test exposing (Test)

    config =
        { frontendApp = Frontend.appFunctions
        , backendApp = Backend.appFunctions
        , handleHttpRequest = always NetworkError_
        , handlePortToJs = always Nothing
        , handleFileRequest = always Nothing
        , domain = unsafeUrl "https://my-app.lamdera.app"
        }

    test : Test
    test =
        Effect.Test.start "myButton is clickable"
            |> Effect.Test.connectFrontend
                sessionId0
                myDomain
                { width = 1920, height = 1080 }
                (\( state, frontendActions ) ->
                    state
                        |> frontendActions.clickButton { htmlId = "myButton" }
                )
            |> Effect.Test.toTest

-}
start :
    Config toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> String
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
start config testName =
    let
        ( backend, effects ) =
            config.backendApp.init

        state : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        state =
            { testName = testName
            , frontendApp = config.frontendApp
            , backendApp = config.backendApp
            , backend = backend
            , pendingEffects = effects
            , frontends = Dict.empty
            , counter = 0
            , elapsedTime = Quantity.zero
            , toBackend = []
            , timers = getTimers startTime (config.backendApp.subscriptions backend)
            , testErrors = []
            , httpRequests = []
            , handleHttpRequest = config.handleHttpRequest
            , handlePortToJs = config.handlePortToJs
            , portRequests = []
            , handleFileRequest = config.handleFileRequest >> Maybe.map Effect.Internal.MockFile
            , domain = config.domain
            , snapshots = []
            }
    in
    Start state


getTimers :
    Time.Posix
    -> Subscription restriction backendMsg
    -> Dict Duration { msg : Time.Posix -> backendMsg, startTime : Time.Posix }
getTimers currentTime backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl (\sub dict -> Dict.union (getTimers currentTime sub) dict) Dict.empty batch

        Effect.Internal.TimeEvery duration msg ->
            Dict.singleton duration { msg = msg, startTime = currentTime }

        Effect.Internal.OnAnimationFrame msg ->
            Dict.singleton (Duration.seconds (1 / 60)) { msg = msg, startTime = currentTime }

        _ ->
            Dict.empty


getClientDisconnectSubs : Effect.Internal.Subscription BackendOnly backendMsg -> List (SessionId -> ClientId -> backendMsg)
getClientDisconnectSubs backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl (\sub list -> getClientDisconnectSubs sub ++ list) [] batch

        Effect.Internal.OnDisconnect msg ->
            [ \sessionId clientId ->
                msg
                    (Effect.Lamdera.sessionIdToString sessionId |> Effect.Internal.SessionId)
                    (Effect.Lamdera.clientIdToString clientId |> Effect.Internal.ClientId)
            ]

        _ ->
            []


getClientConnectSubs : Effect.Internal.Subscription BackendOnly backendMsg -> List (SessionId -> ClientId -> backendMsg)
getClientConnectSubs backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl (\sub list -> getClientConnectSubs sub ++ list) [] batch

        Effect.Internal.OnConnect msg ->
            [ \sessionId clientId ->
                msg
                    (Effect.Lamdera.sessionIdToString sessionId |> Effect.Internal.SessionId)
                    (Effect.Lamdera.clientIdToString clientId |> Effect.Internal.ClientId)
            ]

        _ ->
            []


{-| Add a frontend client to the end to end test

    import Effect.Test
    import Test exposing (Test)

    testApp =
        Effect.Test.testApp
            Frontend.appFunctions
            Backend.appFunctions
            (always NetworkError_)
            (always Nothing)
            (always Nothing)
            (unsafeUrl "https://my-app.lamdera.app")

    test : Test
    test =
        testApp "myButton is clickable"
            |> Effect.Test.connectFrontend
                sessionId0
                myDomain
                { width = 1920, height = 1080 }
                (\( state, frontendActions ) ->
                    state
                        |> frontendActions.clickButton { htmlId = "myButton" }
                )
            |> Effect.Test.toTest

-}
connectFrontend :
    SessionId
    -> Url
    -> { width : Int, height : Int }
    ->
        (( Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
         , FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
         )
         -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        )
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
connectFrontend sessionId url windowSize andThenFunc =
    AndThen
        (\state ->
            let
                clientId =
                    "clientId " ++ String.fromInt state.counter |> Effect.Lamdera.clientIdFromString

                ( frontend, effects ) =
                    state.frontendApp.init url (Effect.Browser.Navigation.fromInternalKey MockNavigationKey)

                subscriptions =
                    state.frontendApp.subscriptions frontend

                ( backend, backendEffects ) =
                    getClientConnectSubs (state.backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                state.backendApp.update (msg sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )

                state2 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
                state2 =
                    { state
                        | frontends =
                            Dict.insert
                                clientId
                                { model = frontend
                                , sessionId = sessionId
                                , pendingEffects = effects
                                , toFrontend = []
                                , clipboard = ""
                                , timers = getTimers (Duration.addTo startTime state.elapsedTime) subscriptions
                                , url = url
                                , windowSize = windowSize
                                }
                                state.frontends
                        , counter = state.counter + 1
                        , backend = backend
                        , pendingEffects = backendEffects
                    }
            in
            andThenFunc
                ( Start state2 |> NextStep "Connect new frontend" identity
                , { clientId = clientId
                  , keyDownEvent = keyDownEvent clientId
                  , clickButton = clickButton clientId
                  , inputText = inputText clientId
                  , clickLink = clickLink clientId
                  , checkView = checkView clientId
                  , update = frontendUpdate clientId
                  , snapshotView = snapshotView clientId
                  }
                )
        )


snapshotView :
    ClientId
    -> { name : String }
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
snapshotView clientId { name } =
    NextStep
        "Snapshot view"
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    { state
                        | snapshots =
                            { name = name
                            , body = state.frontendApp.view frontend.model |> .body
                            , width = frontend.windowSize.width
                            , height = frontend.windowSize.height
                            }
                                :: state.snapshots
                    }

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )


{-| -}
keyDownEvent :
    ClientId
    -> HtmlId
    -> { keyCode : Int }
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
keyDownEvent clientId htmlId { keyCode } =
    userEvent
        ("Key down " ++ String.fromInt keyCode)
        clientId
        htmlId
        ( "keydown", Json.Encode.object [ ( "keyCode", Json.Encode.int keyCode ) ] )


{-| -}
clickButton :
    ClientId
    -> HtmlId
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickButton clientId htmlId =
    userEvent "Click button" clientId htmlId Test.Html.Event.click


{-| -}
inputText :
    ClientId
    -> HtmlId
    -> String
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
inputText clientId htmlId text_ =
    userEvent ("Input text \"" ++ text_ ++ "\"") clientId htmlId (Test.Html.Event.input text_)


normalizeUrl : Url -> String -> String
normalizeUrl domainUrl path =
    if String.startsWith "/" path then
        let
            domain =
                Url.toString domainUrl
        in
        if String.endsWith "/" domain then
            String.dropRight 1 domain ++ path

        else
            domain ++ path

    else
        path


{-| -}
clickLink :
    ClientId
    -> { href : String }
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clickLink clientId { href } =
    NextStep
        ("Click link " ++ href)
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    case
                        state.frontendApp.view frontend.model
                            |> .body
                            |> Html.div []
                            |> Test.Html.Query.fromHtml
                            |> Test.Html.Query.findAll [ Test.Html.Selector.attribute (Html.Attributes.href href) ]
                            |> Test.Html.Query.count
                                (\count ->
                                    if count > 0 then
                                        Expect.pass

                                    else
                                        Expect.fail ("Expected at least one link pointing to " ++ href)
                                )
                            |> Test.Runner.getFailureReason
                    of
                        Nothing ->
                            case Url.fromString (normalizeUrl state.domain href) of
                                Just url ->
                                    let
                                        ( newModel, effects ) =
                                            state.frontendApp.update (state.frontendApp.onUrlRequest (Internal url)) frontend.model
                                    in
                                    { state
                                        | frontends =
                                            Dict.insert
                                                clientId
                                                { frontend
                                                    | model = newModel
                                                    , pendingEffects = Effect.Command.batch [ effects, frontend.pendingEffects ]
                                                }
                                                state.frontends
                                    }

                                Nothing ->
                                    addTestError (InvalidUrl href) state

                        Just _ ->
                            addTestError
                                (CustomError ("Clicking link failed for " ++ href))
                                state

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )


userEvent :
    String
    -> ClientId
    -> HtmlId
    -> ( String, Json.Encode.Value )
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
userEvent name clientId htmlId event =
    let
        htmlIdString =
            Effect.Browser.Dom.idToString htmlId
    in
    NextStep
        (Effect.Lamdera.clientIdToString clientId ++ ": " ++ name ++ " for " ++ htmlIdString)
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        query =
                            state.frontendApp.view frontend.model
                                |> .body
                                |> Html.div []
                                |> Test.Html.Query.fromHtml
                                |> Test.Html.Query.find [ Test.Html.Selector.id htmlIdString ]
                    in
                    case Test.Html.Event.simulate event query |> Test.Html.Event.toResult of
                        Ok msg ->
                            let
                                ( newModel, effects ) =
                                    state.frontendApp.update msg frontend.model
                            in
                            { state
                                | frontends =
                                    Dict.insert
                                        clientId
                                        { frontend
                                            | model = newModel
                                            , pendingEffects = Effect.Command.batch [ effects, frontend.pendingEffects ]
                                        }
                                        state.frontends
                            }

                        Err err ->
                            case Test.Runner.getFailureReason (Test.Html.Query.has [] query) of
                                Just { description } ->
                                    addTestError
                                        (CustomError ("User event failed for element with id " ++ htmlIdString))
                                        state

                                Nothing ->
                                    addTestError
                                        (CustomError ("Unable to find element with id " ++ htmlIdString))
                                        state

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )


formatHtmlError : String -> String
formatHtmlError description =
    let
        stylesStart =
            String.indexes "<style>" description

        stylesEnd =
            String.indexes "</style>" description
    in
    List.map2 Tuple.pair stylesStart stylesEnd
        |> List.foldr
            (\( first, end ) text_ ->
                String.slice 0 (first + String.length "<style>") text_
                    ++ "..."
                    ++ String.slice end (String.length text_ + 999) text_
            )
            description


{-| -}
disconnectFrontend :
    BackendApp toBackend toFrontend backendMsg backendModel
    -> ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, Maybe (FrontendState toBackend frontendMsg frontendModel toFrontend) )
disconnectFrontend backendApp clientId state =
    case Dict.get clientId state.frontends of
        Just frontend ->
            let
                ( backend, effects ) =
                    getClientDisconnectSubs (backendApp.subscriptions state.backend)
                        |> List.foldl
                            (\msg ( newBackend, newEffects ) ->
                                backendApp.update (msg frontend.sessionId clientId) newBackend
                                    |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
                            )
                            ( state.backend, state.pendingEffects )
            in
            ( { state | backend = backend, pendingEffects = effects, frontends = Dict.remove clientId state.frontends }
            , Just { frontend | toFrontend = [] }
            )

        Nothing ->
            ( state, Nothing )


{-| -}
reconnectFrontend :
    BackendApp toBackend toFrontend backendMsg backendModel
    -> FrontendState toBackend frontendMsg frontendModel toFrontend
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, ClientId )
reconnectFrontend backendApp frontendState state =
    let
        clientId =
            "clientId " ++ String.fromInt state.counter |> Effect.Lamdera.clientIdFromString

        ( backend, effects ) =
            getClientConnectSubs (backendApp.subscriptions state.backend)
                |> List.foldl
                    (\msg ( newBackend, newEffects ) ->
                        backendApp.update (msg frontendState.sessionId clientId) newBackend
                            |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
                    )
                    ( state.backend, state.pendingEffects )
    in
    ( { state
        | frontends = Dict.insert clientId frontendState state.frontends
        , backend = backend
        , pendingEffects = effects
        , counter = state.counter + 1
      }
    , clientId
    )


{-| Normally you won't send data directly to the backend and instead use `connectFrontend` followed by things like `clickButton` or `inputText` to cause the frontend to send data to the backend.
If you do need to send data directly, then you can use this though.
-}
sendToBackend :
    SessionId
    -> ClientId
    -> toBackend
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
sendToBackend sessionId clientId toBackend =
    NextStep "Send to backend"
        (\state ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }
        )


animationFrame =
    Duration.seconds (1 / 60)


{-| Copied from elm-community/basics-extra

Perform [modular arithmetic](https://en.wikipedia.org/wiki/Modular_arithmetic)
involving floating point numbers.

The sign of the result is the same as the sign of the `modulus`
in `fractionalModBy modulus x`.

    fractionalModBy 2.5 5 --> 0

    fractionalModBy 2 4.5 == 0.5

    fractionalModBy 2 -4.5 == 1.5

    fractionalModBy -2 4.5 == -1.5

-}
fractionalModBy : Float -> Float -> Float
fractionalModBy modulus x =
    x - modulus * toFloat (floor (x / modulus))


simulateStep :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateStep frontendApp backendApp state =
    let
        newTime =
            Quantity.plus state.elapsedTime animationFrame

        getCompletedTimers : Dict Duration { a | startTime : Time.Posix } -> List ( Duration, { a | startTime : Time.Posix } )
        getCompletedTimers timers =
            Dict.toList timers
                |> List.filter
                    (\( duration, value ) ->
                        let
                            offset : Duration
                            offset =
                                Duration.from startTime value.startTime

                            timerLength : Float
                            timerLength =
                                Duration.inMilliseconds duration
                        in
                        if newTime |> Quantity.minus state.elapsedTime |> Quantity.greaterThanOrEqualTo duration then
                            True

                        else
                            fractionalModBy timerLength (state.elapsedTime |> Quantity.minus offset |> Duration.inMilliseconds)
                                > fractionalModBy timerLength (newTime |> Quantity.minus offset |> Duration.inMilliseconds)
                    )

        ( newBackend, newBackendEffects ) =
            getCompletedTimers state.timers
                |> List.foldl
                    (\( _, { msg } ) ( backend, effects ) ->
                        backendApp.update
                            (msg (Duration.addTo startTime newTime))
                            backend
                            |> Tuple.mapSecond (\a -> Effect.Command.batch [ effects, a ])
                    )
                    ( state.backend, state.pendingEffects )
    in
    { state
        | elapsedTime = newTime
        , pendingEffects = newBackendEffects
        , backend = newBackend
        , frontends =
            Dict.map
                (\_ frontend ->
                    let
                        ( newFrontendModel, newFrontendEffects ) =
                            getCompletedTimers frontend.timers
                                |> Debug.log "timer"
                                |> List.foldl
                                    (\( _, { msg } ) ( frontendModel, effects ) ->
                                        frontendApp.update
                                            (msg (Duration.addTo startTime newTime))
                                            frontendModel
                                            |> Tuple.mapSecond (\a -> Effect.Command.batch [ effects, a ])
                                    )
                                    ( frontend.model, frontend.pendingEffects )
                    in
                    { frontend | pendingEffects = newFrontendEffects, model = newFrontendModel }
                )
                state.frontends
    }
        |> runEffects frontendApp backendApp


{-| Simulate the passage of time.
This will trigger any subscriptions like `Browser.onAnimationFrame` or `Time.every` along the way.

If you need to simulate a large passage of time and are finding that it's taking too long to run, try `fastForward` instead.

-}
simulateTime :
    Duration
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateTime duration =
    NextStep
        ("Simulate time " ++ String.fromFloat (Duration.inSeconds duration) ++ "s")
        (\state -> simulateTimeHelper state.frontendApp state.backendApp duration state)


simulateTimeHelper :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> Duration
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateTimeHelper frontendApp backendApp duration state =
    if duration |> Quantity.lessThan Quantity.zero then
        state

    else
        simulateTimeHelper frontendApp backendApp (duration |> Quantity.minus animationFrame) (simulateStep frontendApp backendApp state)


{-| Similar to `simulateTime` but this will not trigger any `Browser.onAnimationFrame` or `Time.every` subscriptions.

This is useful if you need to move the clock forward a week and it would take too long to simulate it perfectly.

-}
fastForward :
    Duration
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
fastForward duration =
    NextStep
        ("Fast forward " ++ String.fromFloat (Duration.inSeconds duration) ++ "s")
        (\state -> { state | elapsedTime = Quantity.plus state.elapsedTime duration })


{-| Sometimes you need to decide what should happen next based on some current state.
In order to do that you can write something like this:

    import Effect.Test

    state
        |> Effect.Test.andThen
            (\state2 ->
                case List.filterMap isLoginEmail state2.httpRequests |> List.head of
                    Just loginEmail ->
                        Effect.Test.continueWith state2
                                |> testApp.connectFrontend
                                    sessionIdFromEmail
                                    (loginEmail.loginUrl)
                                    (\( state3, clientIdFromEmail ) ->
                                        ...
                                    )

                    Nothing ->
                        Effect.Test.continueWith state2 |> Effect.Test.checkState (\_ -> Err "Should have gotten a login email")
            )

-}
andThen :
    (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
andThen =
    AndThen


{-| Sometimes you need to decide what should happen next based on some current state.
In order to do that you can write something like this:

    import Effect.Test

    state
        |> Effect.Test.andThen
            (\state2 ->
                case List.filterMap isLoginEmail state2.httpRequests |> List.head of
                    Just loginEmail ->
                        Effect.Test.continueWith state2
                                |> testApp.connectFrontend
                                    sessionIdFromEmail
                                    (loginEmail.loginUrl)
                                    (\( state3, clientIdFromEmail ) ->
                                        ...
                                    )

                    Nothing ->
                        Effect.Test.continueWith state2 |> Effect.Test.checkState (\_ -> Err "Should have gotten a login email")
            )

-}
continueWith : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
continueWith state =
    Start state


runEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runEffects frontendApp backendApp state =
    let
        state2 =
            runBackendEffects frontendApp backendApp state.pendingEffects (clearBackendEffects state)

        state4 =
            Dict.foldl
                (\clientId { sessionId, pendingEffects } state3 ->
                    runFrontendEffects
                        frontendApp
                        sessionId
                        clientId
                        pendingEffects
                        (clearFrontendEffects clientId state3)
                )
                state2
                state2.frontends
    in
    { state4
        | pendingEffects = flattenEffects state4.pendingEffects |> Effect.Command.batch
        , frontends =
            Dict.map
                (\_ frontend ->
                    { frontend | pendingEffects = flattenEffects frontend.pendingEffects |> Effect.Command.batch }
                )
                state4.frontends
    }
        |> runNetwork frontendApp backendApp


runNetwork :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runNetwork frontendApp backendApp state =
    let
        ( backendModel, effects ) =
            List.foldl
                (\( sessionId, clientId, toBackendMsg ) ( model, effects2 ) ->
                    backendApp.updateFromFrontend sessionId clientId toBackendMsg model
                        |> Tuple.mapSecond (\a -> Effect.Command.batch [ effects2, a ])
                )
                ( state.backend, state.pendingEffects )
                state.toBackend

        frontends =
            Dict.map
                (\_ frontend ->
                    let
                        ( newModel, newEffects2 ) =
                            List.foldl
                                (\msg ( model, newEffects ) ->
                                    frontendApp.updateFromBackend msg model
                                        |> Tuple.mapSecond (\a -> Effect.Command.batch [ newEffects, a ])
                                )
                                ( frontend.model, frontend.pendingEffects )
                                frontend.toFrontend
                    in
                    { frontend
                        | model = newModel
                        , pendingEffects = newEffects2
                        , toFrontend = []
                    }
                )
                state.frontends
    in
    { state
        | toBackend = []
        , backend = backendModel
        , pendingEffects = flattenEffects effects |> Effect.Command.batch
        , frontends = frontends
    }


clearBackendEffects :
    State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clearBackendEffects state =
    { state | pendingEffects = Effect.Command.none }


clearFrontendEffects :
    ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
clearFrontendEffects clientId state =
    { state
        | frontends =
            Dict.update
                clientId
                (Maybe.map (\frontend -> { frontend | pendingEffects = None }))
                state.frontends
    }


runFrontendEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> SessionId
    -> ClientId
    -> Command FrontendOnly toBackend frontendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runFrontendEffects frontendApp sessionId clientId effectsToPerform state =
    case effectsToPerform of
        Batch nestedEffectsToPerform ->
            List.foldl (runFrontendEffects frontendApp sessionId clientId) state nestedEffectsToPerform

        SendToBackend toBackend ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }

        NavigationPushUrl _ urlText ->
            handleUrlChange frontendApp urlText clientId state

        NavigationReplaceUrl _ urlText ->
            handleUrlChange frontendApp urlText clientId state

        NavigationLoad urlText ->
            handleUrlChange frontendApp urlText clientId state

        NavigationBack _ int ->
            -- TODO
            state

        NavigationForward _ int ->
            -- TODO
            state

        NavigationReload ->
            -- TODO
            state

        NavigationReloadAndSkipCache ->
            -- TODO
            state

        None ->
            state

        Task task ->
            let
                ( newState, msg ) =
                    runTask (Just clientId) frontendApp state task
            in
            case Dict.get clientId newState.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update msg frontend.model
                    in
                    { newState
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = Effect.Command.batch [ frontend.pendingEffects, effects ]
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        Port portName _ value ->
            let
                portRequest =
                    { clientId = clientId, portName = portName, value = value }

                newState =
                    { state | portRequests = portRequest :: state.portRequests }
            in
            case
                newState.handlePortToJs
                    { currentRequest = portRequest
                    , pastRequests = state.portRequests
                    }
            of
                Just ( responsePortName, responseValue ) ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            let
                                msgs : List (Json.Decode.Value -> frontendMsg)
                                msgs =
                                    frontendApp.subscriptions frontend.model
                                        |> getPortSubscriptions
                                        |> List.filterMap
                                            (\sub ->
                                                if sub.portName == responsePortName then
                                                    Just sub.msg

                                                else
                                                    Nothing
                                            )

                                ( model, effects ) =
                                    List.foldl
                                        (\msg ( model_, effects_ ) ->
                                            let
                                                ( newModel, newEffects ) =
                                                    frontendApp.update (msg responseValue) model_
                                            in
                                            ( newModel, Effect.Command.batch [ effects_, newEffects ] )
                                        )
                                        ( frontend.model, frontend.pendingEffects )
                                        msgs
                            in
                            { newState
                                | frontends =
                                    Dict.insert clientId
                                        { frontend | model = model, pendingEffects = effects }
                                        newState.frontends
                            }

                        Nothing ->
                            newState

                Nothing ->
                    newState

        SendToFrontend _ _ ->
            state

        SendToFrontends _ _ ->
            state

        FileDownloadUrl _ ->
            state

        FileDownloadString _ ->
            state

        FileDownloadBytes _ ->
            state

        FileSelectFile mimeTypes msg ->
            case state.handleFileRequest { mimeTypes = mimeTypes } of
                Just file ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            let
                                ( model, effects ) =
                                    frontendApp.update (msg file) frontend.model
                            in
                            { state
                                | frontends =
                                    Dict.insert clientId
                                        { frontend
                                            | model = model
                                            , pendingEffects = Effect.Command.batch [ frontend.pendingEffects, effects ]
                                        }
                                        state.frontends
                            }

                        Nothing ->
                            state

                Nothing ->
                    state

        FileSelectFiles strings function ->
            -- TODO
            state

        Broadcast _ ->
            state

        HttpCancel string ->
            -- TODO
            state

        Passthrough cmd ->
            state


getPortSubscriptions :
    Subscription FrontendOnly frontendMsg
    -> List { portName : String, msg : Json.Decode.Value -> frontendMsg }
getPortSubscriptions subscription =
    case subscription of
        Effect.Internal.SubBatch subscriptions ->
            List.concatMap getPortSubscriptions subscriptions

        Effect.Internal.SubPort portName _ msg ->
            [ { portName = portName, msg = msg } ]

        _ ->
            []


handleUrlChange :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> String
    -> ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleUrlChange frontendApp urlText clientId state =
    let
        urlText_ =
            normalizeUrl state.domain urlText
    in
    case Url.fromString urlText_ of
        Just url ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        ( model, effects ) =
                            frontendApp.update (frontendApp.onUrlChange url) frontend.model
                    in
                    { state
                        | frontends =
                            Dict.insert clientId
                                { frontend
                                    | model = model
                                    , pendingEffects = Effect.Command.batch [ frontend.pendingEffects, effects ]
                                    , url = url
                                }
                                state.frontends
                    }

                Nothing ->
                    state

        Nothing ->
            state


flattenEffects : Command restriction toBackend frontendMsg -> List (Command restriction toBackend frontendMsg)
flattenEffects effect =
    case effect of
        Batch effects ->
            List.concatMap flattenEffects effects

        None ->
            []

        _ ->
            [ effect ]


runBackendEffects :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> Command BackendOnly toFrontend backendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runBackendEffects frontendApp backendApp effect state =
    case effect of
        Batch effects ->
            List.foldl (runBackendEffects frontendApp backendApp) state effects

        SendToFrontend (Effect.Internal.ClientId clientId) toFrontend ->
            { state
                | frontends =
                    Dict.update
                        (Effect.Lamdera.clientIdFromString clientId)
                        (Maybe.map (\frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }))
                        state.frontends
            }

        SendToFrontends (Effect.Internal.SessionId sessionId) toFrontend ->
            let
                sessionId_ =
                    Effect.Lamdera.sessionIdFromString sessionId
            in
            { state
                | frontends =
                    Dict.map
                        (\_ frontend ->
                            if frontend.sessionId == sessionId_ then
                                { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] }

                            else
                                frontend
                        )
                        state.frontends
            }

        None ->
            state

        Task task ->
            let
                ( newState, msg ) =
                    runTask Nothing frontendApp state task

                ( model, effects ) =
                    backendApp.update msg newState.backend
            in
            { newState
                | backend = model
                , pendingEffects = Effect.Command.batch [ newState.pendingEffects, effects ]
            }

        SendToBackend _ ->
            state

        NavigationPushUrl _ _ ->
            state

        NavigationReplaceUrl _ _ ->
            state

        NavigationLoad _ ->
            state

        NavigationBack _ _ ->
            state

        NavigationForward _ _ ->
            state

        NavigationReload ->
            state

        NavigationReloadAndSkipCache ->
            state

        Port _ _ _ ->
            state

        FileDownloadUrl _ ->
            state

        FileDownloadString _ ->
            state

        FileDownloadBytes _ ->
            state

        FileSelectFile _ _ ->
            state

        FileSelectFiles _ _ ->
            state

        Broadcast toFrontend ->
            { state
                | frontends =
                    Dict.map
                        (\_ frontend -> { frontend | toFrontend = frontend.toFrontend ++ [ toFrontend ] })
                        state.frontends
            }

        HttpCancel string ->
            -- TODO
            state

        Passthrough cmd ->
            state


runTask :
    Maybe ClientId
    -> FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Task restriction x x
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, x )
runTask maybeClientId frontendApp state task =
    case task of
        Succeed value ->
            ( state, value )

        Fail value ->
            ( state, value )

        HttpStringTask httpRequest ->
            -- TODO: Implement actual delays to http requests
            let
                request : HttpRequest
                request =
                    { requestedBy =
                        case maybeClientId of
                            Just clientId ->
                                RequestedByFrontend clientId

                            Nothing ->
                                RequestedByBackend
                    , method = httpRequest.method
                    , url = httpRequest.url
                    , body = httpBodyFromInternal httpRequest.body
                    , headers = httpRequest.headers
                    }
            in
            state.handleHttpRequest { currentRequest = request, pastRequests = state.httpRequests }
                |> (\a ->
                        case a of
                            BadUrlResponse url ->
                                Http.BadUrl_ url

                            TimeoutResponse ->
                                Http.Timeout_

                            NetworkErrorResponse ->
                                Http.NetworkError_

                            BadStatusResponse metadata text2 ->
                                Http.BadStatus_ metadata text2

                            BytesHttpResponse metadata body ->
                                case Bytes.Decode.decode (Bytes.Decode.string (Bytes.width body)) body of
                                    Just text2 ->
                                        Http.GoodStatus_ metadata text2

                                    Nothing ->
                                        Http.BadStatus_ metadata "Test error: Response contains bytes that aren't valid a valid string"

                            StringHttpResponse metadata text2 ->
                                Http.GoodStatus_ metadata text2

                            JsonHttpResponse metadata body ->
                                Http.GoodStatus_ metadata (Json.Encode.encode 0 body)

                            TextureHttpResponse metadata _ ->
                                Http.BadStatus_
                                    metadata
                                    "Test error: Can't convert texture data to string"
                   )
                |> httpRequest.onRequestComplete
                |> runTask maybeClientId frontendApp { state | httpRequests = request :: state.httpRequests }

        HttpBytesTask httpRequest ->
            -- TODO: Implement actual delays to http requests
            let
                request : HttpRequest
                request =
                    { requestedBy =
                        case maybeClientId of
                            Just clientId ->
                                RequestedByFrontend clientId

                            Nothing ->
                                RequestedByBackend
                    , method = httpRequest.method
                    , url = httpRequest.url
                    , body = httpBodyFromInternal httpRequest.body
                    , headers = httpRequest.headers
                    }
            in
            state.handleHttpRequest { currentRequest = request, pastRequests = state.httpRequests }
                |> (\a ->
                        case a of
                            BadUrlResponse url ->
                                Http.BadUrl_ url

                            TimeoutResponse ->
                                Http.Timeout_

                            NetworkErrorResponse ->
                                Http.NetworkError_

                            BadStatusResponse metadata text2 ->
                                Http.BadStatus_ metadata (Bytes.Encode.string text2 |> Bytes.Encode.encode)

                            BytesHttpResponse metadata body ->
                                Http.GoodStatus_ metadata body

                            StringHttpResponse metadata text2 ->
                                Http.GoodStatus_ metadata (Bytes.Encode.string text2 |> Bytes.Encode.encode)

                            JsonHttpResponse metadata body ->
                                Http.GoodStatus_
                                    metadata
                                    (Json.Encode.encode 0 body |> Bytes.Encode.string |> Bytes.Encode.encode)

                            TextureHttpResponse metadata _ ->
                                Http.BadStatus_
                                    metadata
                                    (Bytes.Encode.string "Test error: Can't convert texture data to string" |> Bytes.Encode.encode)
                   )
                |> httpRequest.onRequestComplete
                |> runTask maybeClientId frontendApp { state | httpRequests = request :: state.httpRequests }

        SleepTask _ function ->
            -- TODO: Implement actual delays in tasks
            runTask maybeClientId frontendApp state (function ())

        TimeNow gotTime ->
            gotTime (Duration.addTo startTime state.elapsedTime) |> runTask maybeClientId frontendApp state

        TimeHere gotTimeZone ->
            gotTimeZone Time.utc |> runTask maybeClientId frontendApp state

        TimeGetZoneName getTimeZoneName ->
            getTimeZoneName (Time.Offset 0) |> runTask maybeClientId frontendApp state

        GetViewport function ->
            (case maybeClientId of
                Just clientId ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            function
                                { scene =
                                    { width = toFloat frontend.windowSize.width
                                    , height = toFloat frontend.windowSize.height
                                    }
                                , viewport =
                                    { x = 0
                                    , y = 0
                                    , width = toFloat frontend.windowSize.width
                                    , height = toFloat frontend.windowSize.height
                                    }
                                }

                        Nothing ->
                            function { scene = { width = 1920, height = 1080 }, viewport = { x = 0, y = 0, width = 1920, height = 1080 } }

                Nothing ->
                    function { scene = { width = 1920, height = 1080 }, viewport = { x = 0, y = 0, width = 1920, height = 1080 } }
            )
                |> runTask maybeClientId frontendApp state

        SetViewport _ _ function ->
            function () |> runTask maybeClientId frontendApp state

        GetElement htmlId function ->
            getDomTask
                frontendApp
                maybeClientId
                state
                htmlId
                function
                { scene = { width = 100, height = 100 }
                , viewport = { x = 0, y = 0, width = 100, height = 100 }
                , element = { x = 0, y = 0, width = 100, height = 100 }
                }

        FileToString file function ->
            case file of
                Effect.Internal.RealFile _ ->
                    function "" |> runTask maybeClientId frontendApp state

                Effect.Internal.MockFile { content } ->
                    function content |> runTask maybeClientId frontendApp state

        FileToBytes file function ->
            case file of
                Effect.Internal.RealFile _ ->
                    function (Bytes.Encode.encode (Bytes.Encode.sequence []))
                        |> runTask maybeClientId frontendApp state

                Effect.Internal.MockFile { content } ->
                    function (Bytes.Encode.encode (Bytes.Encode.string content))
                        |> runTask maybeClientId frontendApp state

        FileToUrl file function ->
            case file of
                Effect.Internal.RealFile _ ->
                    function "" |> runTask maybeClientId frontendApp state

                Effect.Internal.MockFile { content } ->
                    -- TODO: Don't assume that content is already in a data url format.
                    function content |> runTask maybeClientId frontendApp state

        Focus htmlId function ->
            getDomTask frontendApp maybeClientId state htmlId function ()

        Blur htmlId function ->
            getDomTask frontendApp maybeClientId state htmlId function ()

        GetViewportOf htmlId function ->
            getDomTask
                frontendApp
                maybeClientId
                state
                htmlId
                function
                { scene = { width = 100, height = 100 }
                , viewport = { x = 0, y = 0, width = 100, height = 100 }
                }

        SetViewportOf htmlId _ _ function ->
            getDomTask frontendApp maybeClientId state htmlId function ()

        LoadTexture _ url function ->
            let
                response : HttpResponse
                response =
                    state.handleHttpRequest
                        { currentRequest =
                            { requestedBy =
                                case maybeClientId of
                                    Just clientId ->
                                        RequestedByFrontend clientId

                                    Nothing ->
                                        RequestedByBackend
                            , method = "GET"
                            , url = url
                            , body = EmptyBody
                            , headers = []
                            }
                        , pastRequests = state.httpRequests
                        }
            in
            (case response of
                TextureHttpResponse _ texture ->
                    Ok texture

                _ ->
                    Err WebGLFix.Texture.LoadError
            )
                |> function
                |> runTask maybeClientId frontendApp state


getDomTask :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> Maybe ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> String
    -> (Result Effect.Internal.BrowserDomError value -> Task restriction x x)
    -> value
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, x )
getDomTask frontendApp maybeClientId state htmlId function value =
    (case Maybe.andThen (\clientId -> Dict.get clientId state.frontends) maybeClientId of
        Just frontend ->
            frontendApp.view frontend.model
                |> .body
                |> Html.div []
                |> Test.Html.Query.fromHtml
                |> Test.Html.Query.has [ Test.Html.Selector.id htmlId ]
                |> Test.Runner.getFailureReason
                |> (\a ->
                        if a == Nothing then
                            Effect.Internal.BrowserDomNotFound htmlId |> Err

                        else
                            Ok value
                   )

        Nothing ->
            Effect.Internal.BrowserDomNotFound htmlId |> Err
    )
        |> function
        |> runTask maybeClientId frontendApp state



-- Viewer


{-| -}
type alias Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { navigationKey : Browser.Navigation.Key
    , currentTest : Maybe (TestView frontendModel)
    , testResults : List (Result TestError ())
    , tests : Maybe (Result FileLoadError (List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)))
    }


type alias FileLoadError =
    { name : String
    , error : FileLoadErrorType
    }


type FileLoadErrorType
    = HttpError Http.Error
    | TextureError WebGLFix.Texture.Error


type alias TestView frontendModel =
    { index : Int
    , testName : String
    , stepIndex : Int
    , steps : Nonempty (TestStep frontendModel)
    , overlayPosition : OverlayPosition
    }


type OverlayPosition
    = Top
    | Bottom


type alias TestStep frontendModel =
    { stepName : String
    , errors : List TestError
    , frontends :
        Dict
            ClientId
            { model : frontendModel
            , sessionId : SessionId
            , clipboard : String
            , url : Url
            , windowSize : { width : Int, height : Int }
            }
    }


{-| -}
type Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url
    | PressedViewTest Int
    | PressedStepBackward
    | PressedStepForward
    | PressedBackToOverview
    | ShortPauseFinished
    | NoOp
    | GotFilesForTests (Result FileLoadError (List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)))
    | PressedToggleOverlayPosition


init :
    ()
    -> Url
    -> Browser.Navigation.Key
    ->
        ( Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        , Cmd (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
        )
init _ _ navigationKey =
    ( { navigationKey = navigationKey, currentTest = Nothing, testResults = [], tests = Nothing }
    , Process.sleep 0 |> Task.perform (\() -> ShortPauseFinished)
    )


update :
    ViewerWith (List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel))
    -> Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    ->
        ( Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        , Cmd (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
        )
update config msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Browser.Internal _ ->
                    ( model, Cmd.none )

                Browser.External url ->
                    ( model, Browser.Navigation.load url )

        UrlChanged _ ->
            ( model, Cmd.none )

        PressedViewTest index ->
            case model.tests of
                Just (Err error) ->
                    ( model, Cmd.none )

                Just (Ok tests) ->
                    case getAt index tests of
                        Just test ->
                            let
                                state =
                                    instructionsToState test
                            in
                            ( { model
                                | currentTest =
                                    { index = index
                                    , testName = state.testName
                                    , steps =
                                        List.Nonempty.map
                                            (\( stepName, state_ ) ->
                                                { stepName = stepName
                                                , errors = state_.testErrors
                                                , frontends =
                                                    Dict.map
                                                        (\_ frontend ->
                                                            { model = frontend.model
                                                            , sessionId = frontend.sessionId
                                                            , clipboard = frontend.clipboard
                                                            , url = frontend.url
                                                            , windowSize = frontend.windowSize
                                                            }
                                                        )
                                                        state_.frontends
                                                }
                                            )
                                            (flatten test)
                                    , stepIndex = 0
                                    , overlayPosition = Top
                                    }
                                        |> Just
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        PressedStepForward ->
            ( { model
                | currentTest =
                    case model.currentTest of
                        Just currentTest ->
                            { currentTest
                                | stepIndex =
                                    min (List.Nonempty.length currentTest.steps - 1) (currentTest.stepIndex + 1)
                            }
                                |> Just

                        Nothing ->
                            Nothing
              }
            , Cmd.none
            )

        PressedStepBackward ->
            ( { model
                | currentTest =
                    case model.currentTest of
                        Just currentTest ->
                            { currentTest | stepIndex = max 0 (currentTest.stepIndex - 1) }
                                |> Just

                        Nothing ->
                            Nothing
              }
            , Cmd.none
            )

        PressedBackToOverview ->
            ( { model | currentTest = Nothing }, Cmd.none )

        ShortPauseFinished ->
            ( model, Task.attempt GotFilesForTests config.cmds )

        GotFilesForTests result ->
            case result of
                Ok tests ->
                    case getAt (List.length model.testResults) tests of
                        Just test ->
                            ( { model
                                | testResults =
                                    model.testResults
                                        ++ [ case instructionsToState test |> .testErrors of
                                                firstError :: _ ->
                                                    Err firstError

                                                [] ->
                                                    Ok ()
                                           ]
                                , tests = Just (Ok tests)
                              }
                            , Process.sleep 0 |> Task.perform (\() -> ShortPauseFinished)
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Err error ->
                    ( { model | tests = Just (Err error) }, Cmd.none )

        PressedToggleOverlayPosition ->
            ( { model
                | currentTest =
                    case model.currentTest of
                        Just currentTest ->
                            { currentTest
                                | overlayPosition =
                                    case currentTest.overlayPosition of
                                        Top ->
                                            Bottom

                                        Bottom ->
                                            Top
                            }
                                |> Just

                        Nothing ->
                            Nothing
              }
            , Cmd.none
            )


view :
    Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Browser.Document (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
view model =
    { title = "Test viewer"
    , body =
        [ case model.tests of
            Just (Ok tests) ->
                case model.currentTest of
                    Just testView_ ->
                        case getAt testView_.index tests of
                            Just instructions ->
                                testView instructions testView_

                            Nothing ->
                                text "Invalid index for tests"

                    Nothing ->
                        overview tests model.testResults

            Just (Err error) ->
                "Failed to load \""
                    ++ error.name
                    ++ "\" "
                    ++ (case error.error of
                            HttpError Http.NetworkError ->
                                "due to a network error"

                            HttpError (Http.BadUrl _) ->
                                "because the path is invalid"

                            HttpError Http.Timeout ->
                                "due to a network timeout"

                            HttpError (Http.BadStatus code) ->
                                "and instead got a " ++ String.fromInt code ++ " error"

                            HttpError (Http.BadBody _) ->
                                "due to a bad response body"

                            TextureError WebGLFix.Texture.LoadError ->
                                "due to the file not being found or a network error"

                            TextureError (WebGLFix.Texture.SizeError w h) ->
                                "due to the texture being an invalid size (width: " ++ String.fromInt w ++ ", height: " ++ String.fromInt h ++ ")"
                       )
                    |> text

            Nothing ->
                text "Loading files for tests..."
        ]
    }


getAt : Int -> List a -> Maybe a
getAt index list =
    List.drop index list |> List.head


overview :
    List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> List (Result TestError ())
    -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
overview tests testResults_ =
    List.foldl
        (\test { index, testResults, elements } ->
            { index = index + 1
            , testResults = List.drop 1 testResults
            , elements =
                Html.div
                    []
                    [ button (PressedViewTest index) (getTestName test)
                    , case testResults of
                        (Ok ()) :: _ ->
                            Html.span
                                [ Html.Attributes.style "color" "rgb(0, 200, 0)"
                                , Html.Attributes.style "padding" "4px"
                                ]
                                [ Html.text "Passed" ]

                        (Err head) :: _ ->
                            Html.span
                                [ Html.Attributes.style "color" "rgb(200, 10, 10)"
                                , Html.Attributes.style "padding" "4px"
                                ]
                                [ Html.text (testErrorToString head) ]

                        [] ->
                            Html.text ""
                    ]
                    :: elements
            }
        )
        { index = 0, testResults = testResults_, elements = [] }
        tests
        |> .elements
        |> List.reverse
        |> (::) (titleText "End to end test viewer")
        |> Html.div
            [ Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "font-family" "arial"
            , Html.Attributes.style "font-size" "16px"
            ]


button : msg -> String -> Html msg
button onPress text_ =
    Html.button
        [ Html.Events.onClick onPress
        , Html.Attributes.style "padding" "8px"
        ]
        [ Html.text text_ ]


overlayButton : msg -> String -> Html msg
overlayButton onPress text_ =
    Html.button
        [ Html.Events.onClick onPress
        , Html.Attributes.style "padding" "2px"
        ]
        [ Html.text text_ ]


text : String -> Html msg
text text_ =
    Html.div
        [ Html.Attributes.style "padding" "4px"
        ]
        [ Html.text text_ ]


titleText : String -> Html msg
titleText text_ =
    Html.h1
        [ Html.Attributes.style "font-size" "20px"
        ]
        [ Html.text text_ ]


getViewFunc : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> frontendModel -> List (Html frontendMsg)
getViewFunc instructions =
    case instructions of
        NextStep _ _ instructions_ ->
            getViewFunc instructions_

        AndThen _ instructions_ ->
            getViewFunc instructions_

        Start state ->
            \model -> state.frontendApp.view model |> .body


getTestName : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> String
getTestName instructions =
    case instructions of
        NextStep _ _ instructions_ ->
            getTestName instructions_

        AndThen _ instructions_ ->
            getTestName instructions_

        Start state ->
            state.testName


testView :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> TestView frontendModel
    -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
testView instructions testView_ =
    let
        viewFunc : frontendModel -> List (Html frontendMsg)
        viewFunc =
            getViewFunc instructions

        currentStep =
            List.Nonempty.get testView_.stepIndex testView_.steps
    in
    Html.div
        []
        (testOverlay testView_ currentStep
            :: List.map
                (\( _, frontend ) ->
                    Html.div [] (viewFunc frontend.model) |> Html.map (\_ -> NoOp)
                )
                (Dict.toList currentStep.frontends)
        )



--Html.div
--                        []
--                        [ "ClientId: " ++ Effect.Lamdera.clientIdToString clientId |> ellipsis 600
--                        , Url.toString frontend.url |> ellipsis 600


testOverlay : TestView frontendModel -> TestStep frontendModel -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
testOverlay testView_ currentStep =
    Html.div
        [ Html.Attributes.style "padding" "4px"
        , Html.Attributes.style "font-family" "arial"
        , Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "color" "white"
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "background" "#424242ff"
        , case testView_.overlayPosition of
            Top ->
                Html.Attributes.style "top" "0"

            Bottom ->
                Html.Attributes.style "bottom" "0"
        , case testView_.overlayPosition of
            Top ->
                Html.Attributes.style "border-radius" "0 0 8px 0"

            Bottom ->
                Html.Attributes.style "border-radius" "0 8px 0 0"
        ]
        [ Html.div
            []
            [ overlayButton PressedBackToOverview "Close"
            , Html.div [ Html.Attributes.style "display" "inline-block", Html.Attributes.style "padding" "4px" ] []
            , overlayButton PressedToggleOverlayPosition "Move"
            , Html.div [ Html.Attributes.style "display" "inline-block", Html.Attributes.style "padding" "4px" ] []
            , overlayButton PressedStepBackward "Previous"
            , overlayButton PressedStepForward "Next step"
            , Html.div
                [ Html.Attributes.style "display" "inline-block"
                , Html.Attributes.style "padding" "4px"
                ]
                [ Html.text
                    (" "
                        ++ String.fromInt (testView_.stepIndex + 1)
                        ++ "/"
                        ++ String.fromInt (List.Nonempty.length testView_.steps)
                        ++ (" " ++ currentStep.stepName)
                    )
                ]
            ]
        , Html.div
            [ Html.Attributes.style "color" "rgb(200, 10, 10)"
            ]
            (List.map (testErrorToString >> text) currentStep.errors)
        ]


ellipsis : Int -> String -> Html msg
ellipsis width text_ =
    Html.div
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "width" (String.fromInt width ++ "px")
        , Html.Attributes.style "overflow-x" "hidden"
        , Html.Attributes.style "padding" "4px"
        ]
        [ Html.text text_ ]


buttonAttributes : List (Html.Attribute msg)
buttonAttributes =
    []


{-| -}
type alias ViewerWith a =
    { cmds : Task.Task FileLoadError a }


{-| View your end-to-end tests in a elm reactor style app.

    import Effect.Test

    main =
        Effect.Test.viewerWith
            (\image jsonData ->
                [{- End to end tests go here -}]
            )
            |> Effect.Test.addBytesFile "/test.png"
            |> Effect.Test.addBytesFile "/data.json"
            |> Effect.Test.startViewer

-}
viewerWith : a -> ViewerWith a
viewerWith a =
    { cmds = Task.succeed a }


{-| View your end-to-end tests in a elm reactor style app.

    import Effect.Test

    main =
        Effect.Test.viewerWith
            (\image jsonData ->
                [{- End to end tests go here -}]
            )
            |> Effect.Test.addBytesFile "/test.png"
            |> Effect.Test.addBytesFile "/data.json"
            |> Effect.Test.startViewer

-}
startViewer :
    ViewerWith (List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel))
    -> Program () (Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
startViewer viewerWith2 =
    Browser.application
        { init = init
        , update = update viewerWith2
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        }


{-| View your end-to-end tests in a elm reactor style app.

        main =
            viewer [{- End to end tests go here -}]

-}
viewer :
    List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Program () (Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel) (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
viewer tests =
    Browser.application
        { init = init
        , update = update { cmds = Task.succeed tests }
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        }


{-| Add a file containing binary data to your tests. Right now this is performed with HTTP get requests which means you can only access files in /public (or make get requests to other websites though this isn't recommended since this API might change in the future)

    import Effect.Test

    main =
        Effect.Test.viewerWith
            (\image jsonData ->
                [{- End to end tests go here -}]
            )
            |> Effect.Test.addBytesFile "/test.png"
            |> Effect.Test.addBytesFile "/data.json"
            |> Effect.Test.startViewer

-}
addBytesFile : String -> ViewerWith (Bytes -> b) -> ViewerWith b
addBytesFile file model =
    { cmds =
        Task.andThen
            (\tests ->
                Http.task
                    { method = "GET"
                    , headers = []
                    , body = Http.emptyBody
                    , url = file
                    , resolver =
                        Http.bytesResolver
                            (\response ->
                                case response of
                                    Http.BadUrl_ string ->
                                        Err { name = file, error = Http.BadUrl string |> HttpError }

                                    Http.Timeout_ ->
                                        Err { name = file, error = Http.Timeout |> HttpError }

                                    Http.NetworkError_ ->
                                        Err { name = file, error = Http.NetworkError |> HttpError }

                                    Http.BadStatus_ metadata _ ->
                                        Err { name = file, error = Http.BadStatus metadata.statusCode |> HttpError }

                                    Http.GoodStatus_ _ body ->
                                        Ok (tests body)
                            )
                    , timeout = Just 30000
                    }
            )
            model.cmds
    }


{-| Add a file containing data for a `Effect.WebGL.Texture.Texture` to your tests. Right now this is performed with HTTP get requests which means you can only access files in /public (or make get requests to other websites though this isn't recommended since this API might change in the future)

    import Effect.Test

    main =
        Effect.Test.viewerWith
            (\texture ->
                [{- End to end tests go here -}]
            )
            |> Effect.Test.addTextureFile "/texture.png"
            |> Effect.Test.startViewer

-}
addTexture : String -> ViewerWith (Effect.WebGL.Texture.Texture -> b) -> ViewerWith b
addTexture file model =
    { cmds =
        Task.andThen
            (\tests ->
                WebGLFix.Texture.load file
                    |> Task.mapError (\error -> { name = file, error = TextureError error })
                    |> Task.map tests
            )
            model.cmds
    }


{-| Add a file containing data for a `Effect.WebGL.Texture.Texture` to your tests. Right now this is performed with HTTP get requests which means you can only access files in /public (or make get requests to other websites though this isn't recommended since this API might change in the future)

    import Effect.Test

    main =
        Effect.Test.viewerWith
            (\texture ->
                [{- End to end tests go here -}]
            )
            |> Effect.Test.addTextureFileWithOptions
                -- WebGL texture options go here
                "/texture.png"
            |> Effect.Test.startViewer

-}
addTextureWithOptions : Effect.WebGL.Texture.Options -> String -> ViewerWith (Effect.WebGL.Texture.Texture -> b) -> ViewerWith b
addTextureWithOptions options file model =
    let
        convertWrap : Effect.Internal.Wrap -> WebGLFix.Texture.Wrap
        convertWrap wrap =
            case wrap of
                Effect.Internal.Repeat ->
                    WebGLFix.Texture.repeat

                Effect.Internal.ClampToEdge ->
                    WebGLFix.Texture.clampToEdge

                Effect.Internal.MirroredRepeat ->
                    WebGLFix.Texture.mirroredRepeat
    in
    { cmds =
        Task.andThen
            (\tests ->
                WebGLFix.Texture.loadWith
                    { magnify =
                        case options.magnify of
                            Effect.Internal.Linear ->
                                WebGLFix.Texture.linear

                            _ ->
                                WebGLFix.Texture.nearest
                    , minify =
                        case options.minify of
                            Effect.Internal.Linear ->
                                WebGLFix.Texture.linear

                            Effect.Internal.Nearest ->
                                WebGLFix.Texture.nearest

                            Effect.Internal.NearestMipmapNearest ->
                                WebGLFix.Texture.nearestMipmapNearest

                            Effect.Internal.LinearMipmapNearest ->
                                WebGLFix.Texture.linearMipmapNearest

                            Effect.Internal.NearestMipmapLinear ->
                                WebGLFix.Texture.nearestMipmapLinear

                            Effect.Internal.LinearMipmapLinear ->
                                WebGLFix.Texture.linearMipmapLinear
                    , horizontalWrap = convertWrap options.horizontalWrap
                    , verticalWrap = convertWrap options.verticalWrap
                    , flipY = options.flipY
                    , premultiplyAlpha = options.premultiplyAlpha
                    }
                    file
                    |> Task.mapError (\error -> { name = file, error = TextureError error })
                    |> Task.map tests
            )
            model.cmds
    }
