module Effect.Test exposing
    ( start, Config, connectFrontend, FrontendApp, BackendApp, HttpRequest, HttpResponse(..), RequestedBy(..), PortToJs, FileData, FileUpload(..), MultipleFilesUpload(..), uploadBytesFile, uploadStringFile
    , FrontendActions, sendToBackend, simulateTime, fastForward, andThen, continueWith, Instructions, State, startTime, HttpBody(..), HttpPart(..)
    , checkState, checkBackend, toTest, toSnapshots
    , fakeNavigationKey, viewer, Msg, Model, viewerWith, ViewerWith, startViewer, addStringFile, addBytesFile, addTexture, addTextureWithOptions
    )

{-|


## Setting up end to end tests

@docs start, Config, connectFrontend, FrontendApp, BackendApp, HttpRequest, HttpResponse, RequestedBy, PortToJs, FileData, FileUpload, MultipleFilesUpload, uploadBytesFile, uploadStringFile


## Control the tests

@docs FrontendActions, sendToBackend, simulateTime, fastForward, andThen, continueWith, Instructions, State, startTime, HttpBody, HttpPart


## Check the current state

@docs checkState, checkBackend, toTest, toSnapshots


## Test viewer

Sometimes it's hard to tell what's going on in an end to end test. One way to make this easier to use the `viewer` function. It's like a test runner for your browser that also lets you see the frontend of an app as simulated inputs are being triggered.

@docs fakeNavigationKey, viewer, Msg, Model, viewerWith, ViewerWith, startViewer, addStringFile, addBytesFile, addTexture, addTextureWithOptions

-}

import Array exposing (Array)
import AssocList as Dict exposing (Dict)
import Base64
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode
import Bytes.Encode
import DebugParser exposing (ElmValue(..), ExpandableValue(..), SequenceType(..))
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
import Effect.Time
import Effect.TreeView exposing (CollapsedField(..), PathNode)
import Effect.WebGL.Texture
import Expect exposing (Expectation)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Lazy
import Http
import Json.Decode
import Json.Encode
import List.Nonempty exposing (Nonempty)
import Process
import Quantity
import Set
import Task
import Test exposing (Test)
import Test.Html.Event
import Test.Html.Query
import Test.Html.Selector
import Test.Runner
import Time
import Url exposing (Url)
import WebGLFix.Texture


{-| Configure the end to end test before starting it

    import Backend
    import Effect.Test
    import Frontend
    import Test exposing (Test)

    config =
        { frontendApp = Frontend.appFunctions
        , backendApp = Backend.appFunctions
        , handleHttpRequest = always Effect.Test.NetworkErrorResponse
        , handlePortToJs = always Nothing
        , handleFileUpload = always Effect.Test.CancelFileUpload
        , handleMultipleFilesUpload = always Effect.Test.CancelMultiFileUpload
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
    , handleFileUpload : { mimeTypes : List String } -> FileUpload
    , handleMultipleFilesUpload : { mimeTypes : List String } -> MultipleFilesUpload
    , domain : Url
    }


{-| Possible simulated user actions for when `Effect.File.Select.file` is triggered.
-}
type FileUpload
    = CancelFileUpload
    | UploadFile FileData


{-| File data for when simulating a user uploading a file via `Effect.File.Select.file` or `Effect.File.Select.files`
-}
type FileData
    = FileUploadData { name : String, mimeType : String, content : Effect.Internal.FileUploadContent, lastModified : Time.Posix }


{-| Create a file upload containing text data
-}
uploadStringFile : String -> String -> String -> Time.Posix -> FileData
uploadStringFile name mimeType content lastModified =
    FileUploadData
        { name = name
        , mimeType = mimeType
        , content = Effect.Internal.StringFile content
        , lastModified = lastModified
        }


{-| Create a file upload containing binary data
-}
uploadBytesFile : String -> String -> Bytes -> Time.Posix -> FileData
uploadBytesFile name mimeType content lastModified =
    FileUploadData
        { name = name
        , mimeType = mimeType
        , content = Effect.Internal.BytesFile content
        , lastModified = lastModified
        }


{-| Possible simulated user actions for when `Effect.File.Select.files` is triggered.
-}
type MultipleFilesUpload
    = CancelMultipleFilesUpload
    | UploadMultipleFiles FileData (List FileData)


{-| -}
type alias State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { testName : String
    , frontendApp : FrontendApp toBackend frontendMsg frontendModel toFrontend
    , backendApp : BackendApp toBackend toFrontend backendMsg backendModel
    , model : backendModel
    , history : Array (Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    , pendingEffects : Command BackendOnly toFrontend backendMsg
    , frontends : Dict ClientId (FrontendState toBackend frontendMsg frontendModel toFrontend)
    , counter : Int
    , elapsedTime : Duration
    , toBackend : List ( SessionId, ClientId, toBackend )
    , timers : Dict Duration { startTime : Time.Posix }
    , testErrors : List TestError
    , httpRequests : List HttpRequest
    , handleHttpRequest : { currentRequest : HttpRequest, pastRequests : List HttpRequest } -> HttpResponse
    , handlePortToJs :
        { currentRequest : PortToJs, pastRequests : List PortToJs }
        -> Maybe ( String, Json.Decode.Value )
    , portRequests : List PortToJs
    , handleFileUpload : { mimeTypes : List String } -> FileUpload
    , handleMultipleFilesUpload : { mimeTypes : List String } -> MultipleFilesUpload
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
    , sentAt : Time.Posix
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
    | StringBody { contentType : String, content : String }
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
            case checkFunc state.model of
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
                    { state
                        | frontends =
                            Dict.insert
                                clientId
                                (handleUpdate (currentTime state) state.frontendApp msg frontend)
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
    , timers : Dict Duration { startTime : Time.Posix }
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


{-| Start a end-to-end test

    import Backend
    import Effect.Test
    import Frontend
    import Test exposing (Test)

    config =
        { frontendApp = Frontend.appFunctions
        , backendApp = Backend.appFunctions
        , handleHttpRequest = always Effect.Test.NetworkErrorResponse
        , handlePortToJs = always Nothing
        , handleFileUpload = always Effect.Test.CancelFileUpload
        , handleMultipleFilesUpload = always Effect.Test.CancelMultiFileUpload
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
            , model = backend
            , history = Array.empty
            , pendingEffects = effects
            , frontends = Dict.empty
            , counter = 0
            , elapsedTime = Quantity.zero
            , toBackend = []
            , timers = getTimers (config.backendApp.subscriptions backend) |> Dict.map (\_ _ -> { startTime = startTime })
            , testErrors = []
            , httpRequests = []
            , handleHttpRequest = config.handleHttpRequest
            , handlePortToJs = config.handlePortToJs
            , portRequests = []
            , handleFileUpload = config.handleFileUpload
            , handleMultipleFilesUpload = config.handleMultipleFilesUpload
            , domain = config.domain
            , snapshots = []
            }
    in
    Start state


getTimers : Subscription restriction backendMsg -> Dict Duration { msg : Nonempty (Time.Posix -> backendMsg) }
getTimers backendSub =
    case backendSub of
        Effect.Internal.SubBatch batch ->
            List.foldl
                (\sub dict ->
                    Dict.foldl
                        (\duration value dict2 ->
                            Dict.update
                                duration
                                (\maybe ->
                                    (case maybe of
                                        Just data ->
                                            { msg = List.Nonempty.append value.msg data.msg }

                                        Nothing ->
                                            value
                                    )
                                        |> Just
                                )
                                dict2
                        )
                        dict
                        (getTimers sub)
                )
                Dict.empty
                batch

        Effect.Internal.TimeEvery duration msg ->
            Dict.singleton duration { msg = List.Nonempty.singleton msg }

        Effect.Internal.OnAnimationFrame msg ->
            Dict.singleton animationFrame { msg = List.Nonempty.singleton msg }

        Effect.Internal.OnAnimationFrameDelta msg ->
            Dict.singleton animationFrame { msg = List.Nonempty.singleton (\_ -> msg animationFrame) }

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

                state2 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
                state2 =
                    getClientConnectSubs (state.backendApp.subscriptions state.model)
                        |> List.foldl
                            (\msg state3 ->
                                handleUpdate (currentTime state3) state3.backendApp (msg sessionId clientId) state3
                            )
                            state
            in
            andThenFunc
                ( { state2
                    | frontends =
                        Dict.insert
                            clientId
                            { model = frontend
                            , sessionId = sessionId
                            , pendingEffects = effects
                            , toFrontend = []
                            , clipboard = ""
                            , timers = getTimers subscriptions |> Dict.map (\_ _ -> { startTime = currentTime state2 })
                            , url = url
                            , windowSize = windowSize
                            }
                            state2.frontends
                    , counter = state2.counter + 1
                  }
                    |> Start
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


type alias Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { eventType : EventType toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , time : Time.Posix
    , frontends : Dict ClientId (EventFrontend frontendModel)
    , backend : backendModel
    , testErrors : List TestError
    }


type alias EventFrontend frontendModel =
    { model : frontendModel
    , sessionId : SessionId
    , clipboard : String
    , url : Url
    , windowSize : { width : Int, height : Int }
    , cachedElmValue : Maybe ElmValue
    }


type EventType toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    = ToBackendEvent toBackend (Command BackendOnly toFrontend backendMsg)
    | ToFrontendEvent SessionId ClientId toFrontend (Command FrontendOnly toBackend frontendMsg)
    | BackendMsgEvent backendMsg (Command BackendOnly toFrontend backendMsg)
    | FrontendMsgEvent SessionId ClientId frontendMsg (Command FrontendOnly toBackend frontendMsg)
    | TestEvent String


handleUpdate :
    Time.Posix
    -> { b | update : msg -> model -> ( model, Command r toMsg msg ), subscriptions : model -> Subscription r msg }
    -> msg
    ->
        { e
            | model : model
            , pendingEffects : Command r toMsg msg
            , timers : Dict Duration { startTime : Time.Posix }
        }
    ->
        { e
            | model : model
            , pendingEffects : Command r toMsg msg
            , timers : Dict Duration { startTime : Time.Posix }
        }
handleUpdate currentTime2 app msg state =
    let
        ( newModel, cmd ) =
            app.update msg state.model

        subscriptions : Subscription r msg
        subscriptions =
            app.subscriptions newModel

        newTimers : Dict Duration { msg : Nonempty (Time.Posix -> msg) }
        newTimers =
            getTimers subscriptions
    in
    { state
        | model = newModel
        , pendingEffects = Effect.Command.batch [ state.pendingEffects, cmd ]
        , timers =
            Dict.merge
                (\duration _ dict -> Dict.insert duration { startTime = currentTime2 } dict)
                (\_ _ _ dict -> dict)
                (\duration _ dict -> Dict.remove duration dict)
                newTimers
                state.timers
                state.timers
    }


handleUpdateFromBackend :
    Time.Posix
    -> FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> toFrontend
    -> FrontendState toBackend frontendMsg frontendModel toFrontend
    -> FrontendState toBackend frontendMsg frontendModel toFrontend
handleUpdateFromBackend currentTime2 app toFrontend frontendState =
    let
        ( newModel, cmd ) =
            app.updateFromBackend toFrontend frontendState.model

        subscriptions : Subscription FrontendOnly frontendMsg
        subscriptions =
            app.subscriptions newModel

        newTimers : Dict Duration { msg : Nonempty (Time.Posix -> frontendMsg) }
        newTimers =
            getTimers subscriptions
    in
    { frontendState
        | model = newModel
        , pendingEffects = Effect.Command.batch [ frontendState.pendingEffects, cmd ]
        , timers =
            Dict.merge
                (\duration _ dict -> Dict.insert duration { startTime = currentTime2 } dict)
                (\_ _ _ dict -> dict)
                (\duration _ dict -> Dict.remove duration dict)
                newTimers
                frontendState.timers
                frontendState.timers
    }


handleUpdateFromFrontend :
    SessionId
    -> ClientId
    -> toBackend
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleUpdateFromFrontend sessionId clientId msg state =
    let
        ( newModel, cmd ) =
            state.backendApp.updateFromFrontend sessionId clientId msg state.model

        subscriptions : Subscription BackendOnly backendMsg
        subscriptions =
            state.backendApp.subscriptions newModel

        newTimers : Dict Duration { msg : Nonempty (Time.Posix -> backendMsg) }
        newTimers =
            getTimers subscriptions
    in
    { state
        | model = newModel
        , pendingEffects = Effect.Command.batch [ state.pendingEffects, cmd ]
        , history =
            Array.push
                { eventType = ToBackendEvent msg cmd
                , time = currentTime state
                , frontends =
                    Dict.map
                        (\_ a ->
                            { model = a.model
                            , sessionId = a.sessionId
                            , clipboard = a.clipboard
                            , url = a.url
                            , windowSize = a.windowSize
                            , cachedElmValue = Nothing
                            }
                        )
                        state.frontends
                , backend = newModel
                , testErrors = state.testErrors
                }
                state.history
        , timers =
            Dict.merge
                (\duration _ dict -> Dict.insert duration { startTime = currentTime state } dict)
                (\_ _ _ dict -> dict)
                (\duration _ dict -> Dict.remove duration dict)
                newTimers
                state.timers
                state.timers
    }


snapshotView :
    ClientId
    -> { name : String }
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
snapshotView clientId name instructions =
    nextStepHelper
        name
        (\state ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    { state
                        | snapshots =
                            { name = name.name
                            , body = state.frontendApp.view frontend.model |> .body
                            , width = frontend.windowSize.width
                            , height = frontend.windowSize.height
                            }
                                :: state.snapshots
                    }

                Nothing ->
                    addTestError (ClientIdNotFound clientId) state
        )
        instructions


nextStepHelper :
    { name : String }
    ->
        (State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
         -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        )
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
nextStepHelper { name } func instructions =
    NextStep
        name
        (\state ->
            let
                state2 =
                    func state
            in
            { state2
                | history =
                    Array.push
                        { eventType = TestEvent name
                        , time = currentTime state2
                        , frontends =
                            Dict.map
                                (\_ a ->
                                    { model = a.model
                                    , sessionId = a.sessionId
                                    , clipboard = a.clipboard
                                    , url = a.url
                                    , windowSize = a.windowSize
                                    , cachedElmValue = Nothing
                                    }
                                )
                                state2.frontends
                        , backend = state2.model
                        , testErrors = state2.testErrors
                        }
                        state2.history
            }
        )
        instructions


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
                                    { state
                                        | frontends =
                                            Dict.insert
                                                clientId
                                                (handleUpdate
                                                    (currentTime state)
                                                    state.frontendApp
                                                    (state.frontendApp.onUrlRequest (Internal url))
                                                    frontend
                                                )
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
                            { state
                                | frontends =
                                    Dict.insert
                                        clientId
                                        (handleUpdate (currentTime state) state.frontendApp msg frontend)
                                        state.frontends
                            }

                        Err _ ->
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
                state2 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
                state2 =
                    getClientDisconnectSubs (backendApp.subscriptions state.model)
                        |> List.foldl
                            (\msg state3 ->
                                handleUpdate (currentTime state3) state3.backendApp (msg frontend.sessionId clientId) state3
                            )
                            state
            in
            ( { state2 | frontends = Dict.remove clientId state2.frontends }
            , Just { frontend | toFrontend = [] }
            )

        Nothing ->
            ( state, Nothing )


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


animationFrame : Duration
animationFrame =
    Duration.seconds (1 / 60)


timerEndTimes : Dict Duration { startTime : Time.Posix } -> List { endTime : Time.Posix, duration : Duration }
timerEndTimes dict =
    List.map
        (\( duration, a ) -> { endTime = Duration.addTo a.startTime duration, duration = duration })
        (Dict.toList dict)


{-| Find the first minimum element in a list using a comparable transformation. Copied from elm-community/list-extra package
-}
minimumBy : (a -> comparable) -> List a -> Maybe a
minimumBy f ls =
    let
        minBy x ( y, fy ) =
            let
                fx =
                    f x
            in
            if fx < fy then
                ( x, fx )

            else
                ( y, fy )
    in
    case ls of
        [ l_ ] ->
            Just l_

        l_ :: ls_ ->
            Just <| Tuple.first <| List.foldl minBy ( l_, f l_ ) ls_

        _ ->
            Nothing


currentTime : { a | elapsedTime : Duration } -> Time.Posix
currentTime state =
    Time.posixToMillis startTime + elapsedTimeInMillis state |> Time.millisToPosix


elapsedTimeInMillis : { a | elapsedTime : Duration } -> Int
elapsedTimeInMillis state =
    Duration.inMilliseconds state.elapsedTime |> round


getTriggersTimerMsgs :
    (model -> Subscription restriction msg)
    -> { c | timers : Dict Duration { startTime : Time.Posix }, model : model }
    -> Time.Posix
    -> { triggeredMsgs : List msg, completedDurations : List Duration }
getTriggersTimerMsgs subscriptionsFunc state endTime =
    let
        completedDurations : List Duration
        completedDurations =
            List.filterMap
                (\b ->
                    if Time.posixToMillis b.endTime <= Time.posixToMillis endTime then
                        Just b.duration

                    else
                        Nothing
                )
                (timerEndTimes state.timers)
    in
    { triggeredMsgs =
        subscriptionsFunc state.model
            |> getTimers
            |> Dict.filter (\duration _ -> List.member duration completedDurations)
            |> Dict.values
            |> List.concatMap (\value -> List.Nonempty.toList value.msg)
            |> List.map (\msg -> msg endTime)
    , completedDurations = completedDurations
    }


hasPendingEffects : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> Bool
hasPendingEffects state =
    not (List.isEmpty (flattenEffects state.pendingEffects))
        || not (List.isEmpty (List.concatMap (\a -> flattenEffects a.pendingEffects) (Dict.values state.frontends)))


simulateStep :
    Duration
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
simulateStep timeLeft state =
    case
        timerEndTimes state.timers
            ++ List.concatMap (\( _, frontend ) -> timerEndTimes frontend.timers) (Dict.toList state.frontends)
            |> minimumBy (\a -> Time.posixToMillis a.endTime)
    of
        Just nextTimerEnd ->
            let
                delta : Duration
                delta =
                    Duration.from (currentTime state) nextTimerEnd.endTime
            in
            if
                hasPendingEffects state
                    && (timeLeft |> Quantity.greaterThanOrEqualTo animationFrame)
                    && (delta |> Quantity.greaterThan animationFrame)
            then
                runEffects { state | elapsedTime = Quantity.plus animationFrame state.elapsedTime }
                    |> simulateStep (timeLeft |> Quantity.minus animationFrame)

            else if delta |> Quantity.lessThanOrEqualTo timeLeft then
                let
                    state2 =
                        let
                            { triggeredMsgs, completedDurations } =
                                getTriggersTimerMsgs state.backendApp.subscriptions state nextTimerEnd.endTime
                        in
                        List.foldl
                            (handleUpdate nextTimerEnd.endTime state.backendApp)
                            { state | timers = List.foldl Dict.remove state.timers completedDurations }
                            triggeredMsgs
                in
                simulateStep
                    (timeLeft |> Quantity.minus delta)
                    { state2
                        | elapsedTime = Duration.from startTime nextTimerEnd.endTime
                        , frontends =
                            Dict.map
                                (\_ frontend ->
                                    let
                                        { triggeredMsgs, completedDurations } =
                                            getTriggersTimerMsgs state.frontendApp.subscriptions frontend nextTimerEnd.endTime
                                    in
                                    List.foldl
                                        (handleUpdate nextTimerEnd.endTime state.frontendApp)
                                        { frontend | timers = List.foldl Dict.remove frontend.timers completedDurations }
                                        triggeredMsgs
                                )
                                state.frontends
                    }
                    |> runEffects

            else
                { state | elapsedTime = Quantity.plus state.elapsedTime timeLeft }

        Nothing ->
            if hasPendingEffects state && (timeLeft |> Quantity.greaterThanOrEqualTo animationFrame) then
                runEffects { state | elapsedTime = Quantity.plus animationFrame state.elapsedTime }
                    |> simulateStep (timeLeft |> Quantity.minus animationFrame)

            else
                { state | elapsedTime = Quantity.plus state.elapsedTime timeLeft }


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
        (simulateStep duration)


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
    State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runEffects state =
    let
        state2 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        state2 =
            runBackendEffects state.pendingEffects (clearBackendEffects state)

        state4 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        state4 =
            Dict.foldl
                (\clientId { sessionId, pendingEffects } state3 ->
                    runFrontendEffects
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
        |> runNetwork


runNetwork :
    State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runNetwork state =
    let
        state2 : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        state2 =
            List.foldl
                (\( sessionId, clientId, toBackendMsg ) state3 ->
                    handleUpdateFromFrontend sessionId clientId toBackendMsg state3
                )
                state
                state.toBackend
    in
    { state2
        | toBackend = []
        , frontends =
            Dict.map
                (\_ frontend ->
                    List.foldl
                        (handleUpdateFromBackend (currentTime state2) state2.frontendApp)
                        { frontend | toFrontend = [] }
                        frontend.toFrontend
                )
                state2.frontends
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
    SessionId
    -> ClientId
    -> Command FrontendOnly toBackend frontendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runFrontendEffects sessionId clientId effectsToPerform state =
    case effectsToPerform of
        Batch nestedEffectsToPerform ->
            List.foldl (runFrontendEffects sessionId clientId) state nestedEffectsToPerform

        SendToBackend toBackend ->
            { state | toBackend = state.toBackend ++ [ ( sessionId, clientId, toBackend ) ] }

        NavigationPushUrl _ urlText ->
            handleUrlChange urlText clientId state

        NavigationReplaceUrl _ urlText ->
            handleUrlChange urlText clientId state

        NavigationLoad urlText ->
            handleUrlChange urlText clientId state

        NavigationBack _ _ ->
            -- TODO
            state

        NavigationForward _ _ ->
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
                    runTask (Just clientId) state task
            in
            case Dict.get clientId newState.frontends of
                Just frontend ->
                    { newState
                        | frontends =
                            Dict.insert
                                clientId
                                (handleUpdate (currentTime newState) state.frontendApp msg frontend)
                                newState.frontends
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
                                msgs : List frontendMsg
                                msgs =
                                    state.frontendApp.subscriptions frontend.model
                                        |> getPortSubscriptions
                                        |> List.filterMap
                                            (\sub ->
                                                if sub.portName == responsePortName then
                                                    Just (sub.msg responseValue)

                                                else
                                                    Nothing
                                            )
                            in
                            { newState
                                | frontends =
                                    Dict.insert
                                        clientId
                                        (List.foldl (handleUpdate (currentTime state) state.frontendApp) frontend msgs)
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
            case state.handleFileUpload { mimeTypes = mimeTypes } of
                UploadFile (FileUploadData file) ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            { state
                                | frontends =
                                    Dict.insert
                                        clientId
                                        (handleUpdate
                                            (currentTime state)
                                            state.frontendApp
                                            (msg (Effect.Internal.MockFile file))
                                            frontend
                                        )
                                        state.frontends
                            }

                        Nothing ->
                            state

                CancelFileUpload ->
                    state

        FileSelectFiles mimeTypes msg ->
            case state.handleMultipleFilesUpload { mimeTypes = mimeTypes } of
                UploadMultipleFiles (FileUploadData file) files ->
                    case Dict.get clientId state.frontends of
                        Just frontend ->
                            { state
                                | frontends =
                                    Dict.insert
                                        clientId
                                        (handleUpdate
                                            (currentTime state)
                                            state.frontendApp
                                            (msg
                                                (Effect.Internal.MockFile file)
                                                (List.map (\(FileUploadData a) -> Effect.Internal.MockFile a) files)
                                            )
                                            frontend
                                        )
                                        state.frontends
                            }

                        Nothing ->
                            state

                CancelMultipleFilesUpload ->
                    state

        Broadcast _ ->
            state

        HttpCancel _ ->
            -- TODO
            state

        Passthrough _ ->
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
    String
    -> ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
handleUrlChange urlText clientId state =
    let
        urlText_ : String
        urlText_ =
            normalizeUrl state.domain urlText
    in
    case Url.fromString urlText_ of
        Just url ->
            case Dict.get clientId state.frontends of
                Just frontend ->
                    let
                        newFrontend =
                            handleUpdate (currentTime state) state.frontendApp (state.frontendApp.onUrlChange url) frontend
                    in
                    { state | frontends = Dict.insert clientId { newFrontend | url = url } state.frontends }

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
    Command BackendOnly toFrontend backendMsg
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
runBackendEffects effect state =
    case effect of
        Batch effects ->
            List.foldl runBackendEffects state effects

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
                    runTask Nothing state task
            in
            handleUpdate (currentTime newState) state.backendApp msg newState

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

        HttpCancel _ ->
            -- TODO
            state

        Passthrough _ ->
            state


runTask :
    Maybe ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Task restriction x x
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, x )
runTask maybeClientId state task =
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
                    , sentAt = currentTime state
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
                |> runTask maybeClientId { state | httpRequests = request :: state.httpRequests }

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
                    , sentAt = currentTime state
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
                |> runTask maybeClientId { state | httpRequests = request :: state.httpRequests }

        SleepTask _ function ->
            -- TODO: Implement actual delays in tasks
            runTask maybeClientId state (function ())

        TimeNow gotTime ->
            gotTime (currentTime state) |> runTask maybeClientId state

        TimeHere gotTimeZone ->
            gotTimeZone Time.utc |> runTask maybeClientId state

        TimeGetZoneName getTimeZoneName ->
            getTimeZoneName (Time.Offset 0) |> runTask maybeClientId state

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
                |> runTask maybeClientId state

        SetViewport _ _ function ->
            function () |> runTask maybeClientId state

        GetElement htmlId function ->
            getDomTask
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
                    function "" |> runTask maybeClientId state

                Effect.Internal.MockFile { content } ->
                    (case content of
                        Effect.Internal.StringFile a ->
                            a

                        Effect.Internal.BytesFile a ->
                            Bytes.Decode.decode (Bytes.Decode.string (Bytes.width a)) a
                                |> Maybe.withDefault ""
                    )
                        |> function
                        |> runTask maybeClientId state

        FileToBytes file function ->
            case file of
                Effect.Internal.RealFile _ ->
                    function (Bytes.Encode.encode (Bytes.Encode.sequence []))
                        |> runTask maybeClientId state

                Effect.Internal.MockFile { content } ->
                    (case content of
                        Effect.Internal.StringFile a ->
                            Bytes.Encode.encode (Bytes.Encode.string a)

                        Effect.Internal.BytesFile a ->
                            a
                    )
                        |> function
                        |> runTask maybeClientId state

        FileToUrl file function ->
            case file of
                Effect.Internal.RealFile _ ->
                    function "" |> runTask maybeClientId state

                Effect.Internal.MockFile { content } ->
                    (case content of
                        Effect.Internal.StringFile a ->
                            "data:*/*;base64," ++ Maybe.withDefault "" (Base64.fromString a)

                        Effect.Internal.BytesFile a ->
                            "data:*/*;base64," ++ Maybe.withDefault "" (Base64.fromBytes a)
                    )
                        |> function
                        |> runTask maybeClientId state

        Focus htmlId function ->
            getDomTask maybeClientId state htmlId function ()

        Blur htmlId function ->
            getDomTask maybeClientId state htmlId function ()

        GetViewportOf htmlId function ->
            getDomTask
                maybeClientId
                state
                htmlId
                function
                { scene = { width = 100, height = 100 }
                , viewport = { x = 0, y = 0, width = 100, height = 100 }
                }

        SetViewportOf htmlId _ _ function ->
            getDomTask maybeClientId state htmlId function ()

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
                            , sentAt = currentTime state
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
                |> runTask maybeClientId state


getDomTask :
    Maybe ClientId
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> String
    -> (Result Effect.Internal.BrowserDomError value -> Task restriction x x)
    -> value
    -> ( State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel, x )
getDomTask maybeClientId state htmlId function value =
    (case Maybe.andThen (\clientId -> Dict.get clientId state.frontends) maybeClientId of
        Just frontend ->
            state.frontendApp.view frontend.model
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
        |> runTask maybeClientId state



-- Viewer


{-| -}
type alias Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { navigationKey : Browser.Navigation.Key
    , currentTest : Maybe (TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    , testResults : List (Result TestError ())
    , tests : Maybe (Result FileLoadError (List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)))
    , windowSize : ( Int, Int )
    }


type alias FileLoadError =
    { name : String
    , error : FileLoadErrorType
    }


type FileLoadErrorType
    = HttpError Http.Error
    | TextureError WebGLFix.Texture.Error


type alias TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel =
    { index : Int
    , testName : String
    , stepIndex : Int
    , steps : Array (Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    , overlayPosition : OverlayPosition
    , clientId : Maybe ClientId
    , showModel : Bool
    , collapsedFields : RegularDict.Dict (List String) CollapsedField
    }


type OverlayPosition
    = Top
    | Bottom


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
    | SelectedFrontend ClientId
    | PressedShowModel
    | PressedHideModel
    | PressedExpandField (List PathNode)
    | PressedCollapseField (List PathNode)
    | PressedArrowKey ArrowKey
    | ChangedEventSlider String
    | GotWindowSize Int Int


init :
    ()
    -> Url
    -> Browser.Navigation.Key
    ->
        ( Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        , Cmd (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
        )
init _ _ navigationKey =
    let
        _ =
            Debug.log "init" ()
    in
    ( { navigationKey = navigationKey
      , currentTest = Nothing
      , testResults = []
      , tests = Nothing
      , windowSize = ( 1920, 1080 )
      }
    , Cmd.batch
        [ Process.sleep 0 |> Task.perform (\() -> ShortPauseFinished)
        , Browser.Dom.getViewport
            |> Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height))
        ]
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
    (case msg of
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
                    let
                        _ =
                            Debug.log "error" error
                    in
                    ( model, Cmd.none )

                Just (Ok tests) ->
                    case getAt index tests of
                        Just test ->
                            let
                                state : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
                                state =
                                    instructionsToState test
                            in
                            ( { model
                                | currentTest =
                                    { index = index
                                    , testName = state.testName
                                    , steps = state.history
                                    , stepIndex = 0
                                    , overlayPosition = Top
                                    , clientId = Nothing
                                    , showModel = False
                                    , collapsedFields = RegularDict.empty
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
            ( updateCurrentTest (\currentTest -> stepTo (currentTest.stepIndex + 1) currentTest) model, Cmd.none )

        PressedStepBackward ->
            ( updateCurrentTest stepBackward model, Cmd.none )

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
            ( updateCurrentTest
                (\currentTest ->
                    { currentTest
                        | overlayPosition =
                            case currentTest.overlayPosition of
                                Top ->
                                    Bottom

                                Bottom ->
                                    Top
                    }
                )
                model
            , Cmd.none
            )

        SelectedFrontend clientId ->
            ( updateCurrentTest (\currentTest -> { currentTest | clientId = Just clientId }) model, Cmd.none )

        PressedShowModel ->
            ( updateCurrentTest (\currentTest -> { currentTest | showModel = True }) model, Cmd.none )

        PressedHideModel ->
            ( updateCurrentTest (\currentTest -> { currentTest | showModel = False }) model, Cmd.none )

        PressedExpandField pathNodes ->
            ( updateCurrentTest
                (\currentTest ->
                    { currentTest
                        | collapsedFields =
                            RegularDict.insert
                                (List.map Effect.TreeView.pathNodeToKey pathNodes)
                                FieldIsExpanded
                                currentTest.collapsedFields
                    }
                )
                model
            , Cmd.none
            )

        PressedCollapseField pathNodes ->
            ( updateCurrentTest
                (\currentTest ->
                    { currentTest
                        | collapsedFields =
                            RegularDict.insert
                                (List.map Effect.TreeView.pathNodeToKey pathNodes)
                                FieldIsCollapsed
                                currentTest.collapsedFields
                    }
                )
                model
            , Cmd.none
            )

        PressedArrowKey arrowKey ->
            ( updateCurrentTest
                (\currentTest ->
                    case arrowKey of
                        ArrowRight ->
                            stepTo (currentTest.stepIndex + 1) currentTest

                        ArrowLeft ->
                            stepBackward currentTest
                )
                model
            , Cmd.none
            )

        ChangedEventSlider a ->
            case String.toInt a of
                Just stepIndex ->
                    ( updateCurrentTest (stepTo stepIndex) model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GotWindowSize width height ->
            ( { model | windowSize = ( width, height ) }, Cmd.none )
    )
        |> checkCachedElmValue


stepTo : Int -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
stepTo stepIndex currentTest =
    case Array.get stepIndex currentTest.steps of
        Just nextStep ->
            { currentTest
                | stepIndex = stepIndex
                , clientId =
                    case currentTest.clientId of
                        Nothing ->
                            Dict.keys nextStep.frontends |> List.head

                        Just clientId ->
                            Just clientId
            }

        Nothing ->
            currentTest


stepBackward : TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
stepBackward currentTest =
    { currentTest | stepIndex = max 0 (currentTest.stepIndex - 1) }


checkCachedElmValue :
    ( Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    , Cmd (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    )
    ->
        ( Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        , Cmd (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
        )
checkCachedElmValue ( model, cmd ) =
    ( updateCurrentTest
        (\currentTest ->
            case ( currentTest.clientId, model.tests ) of
                ( Just clientId, Just (Ok tests) ) ->
                    { currentTest
                        | steps =
                            checkCachedElmValueHelper clientId currentTest.stepIndex currentTest tests currentTest.steps
                                |> checkCachedElmValueHelper clientId (currentTest.stepIndex - 1) currentTest tests
                    }

                _ ->
                    currentTest
        )
        model
    , cmd
    )


checkCachedElmValueHelper :
    ClientId
    -> Int
    -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> List (Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Array (Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Array (Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
checkCachedElmValueHelper clientId stepIndex currentTest tests steps =
    updateAt
        stepIndex
        (\currentStep ->
            { currentStep
                | frontends =
                    Dict.update
                        clientId
                        (Maybe.map
                            (\frontend ->
                                { frontend
                                    | cachedElmValue =
                                        case ( frontend.cachedElmValue, getAt currentTest.index tests ) of
                                            ( Nothing, Just instructions ) ->
                                                if currentTest.showModel then
                                                    let
                                                        state =
                                                            getState instructions
                                                    in
                                                    toElmValue
                                                        state.frontendApp
                                                        state.backendApp
                                                        currentStep.backend
                                                        frontend

                                                else
                                                    Nothing

                                            _ ->
                                                frontend.cachedElmValue
                                }
                            )
                        )
                        currentStep.frontends
            }
        )
        steps


updateAt : Int -> (b -> b) -> Array b -> Array b
updateAt index mapFunc array =
    case Array.get index array of
        Just item ->
            Array.set index (mapFunc item) array

        Nothing ->
            array


updateCurrentTest :
    (TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    -> Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
updateCurrentTest func model =
    { model
        | currentTest =
            case model.currentTest of
                Just currentTest ->
                    func currentTest |> Just

                Nothing ->
                    Nothing
    }


listGet : Int -> List a -> Maybe a
listGet index list =
    List.drop index list |> List.head


view :
    Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Browser.Document (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
view model =
    { title = "Test viewer"
    , body =
        case model.tests of
            Just (Ok tests) ->
                case model.currentTest of
                    Just testView_ ->
                        case getAt testView_.index tests of
                            Just instructions ->
                                testView (Tuple.first model.windowSize) instructions testView_

                            Nothing ->
                                [ text "Invalid index for tests" ]

                    Nothing ->
                        [ overview tests model.testResults ]

            Just (Err error) ->
                [ "Failed to load \""
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
                ]

            Nothing ->
                [ text "Loading files for tests..." ]
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
                    [ Html.Attributes.style "padding-bottom" "4px" ]
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
            , darkBackground
            , Html.Attributes.style "height" "100vh"
            ]


darkBackground : Html.Attribute msg
darkBackground =
    Html.Attributes.style "background-color" "rgba(0,0,0,0.8)"


button : msg -> String -> Html msg
button onPress text_ =
    Html.button
        [ Html.Events.onClick onPress
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "color" "rgb(10,10,10)"
        , Html.Attributes.style "background-color" "rgb(240,240,240)"
        , Html.Attributes.style "border-width" "0px"
        , Html.Attributes.style "border-radius" "4px"
        ]
        [ Html.text text_ ]


overlayButton : msg -> String -> Html msg
overlayButton onPress text_ =
    Html.button
        [ Html.Events.onClick onPress
        , Html.Attributes.style "padding" "2px"
        , Html.Attributes.style "margin" "0px"
        , Html.Attributes.style "color" "rgb(10,10,10)"
        , Html.Attributes.style "background-color" "rgb(240,240,240)"
        , Html.Attributes.style "border-color" "rgb(250,250,250)"
        , Html.Attributes.style "border-width" "1px"
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "border-style" "solid"
        , Html.Attributes.style "font-family" "arial"
        , Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "font-weight" "regular"
        , Html.Attributes.style "line-height" "1"
        ]
        [ Html.text text_ ]


overlaySelectButton : Bool -> msg -> String -> Html msg
overlaySelectButton isSelected onPress text_ =
    Html.button
        [ Html.Events.onClick onPress
        , Html.Attributes.style "padding" "2px"
        , Html.Attributes.style "color" "rgb(10,10,10)"
        , Html.Attributes.style
            "background-color"
            (if isSelected then
                "rgb(180,200,255)"

             else
                "rgb(240,240,240)"
            )
        , Html.Attributes.style "border-color" "rgb(250,250,250)"
        , Html.Attributes.style "border-width" "1px"
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "border-style" "solid"
        , Html.Attributes.style "font-family" "arial"
        , Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "font-weight" "regular"
        , Html.Attributes.style "line-height" "1"
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
        , defaultFontColor
        ]
        [ Html.text text_ ]


defaultFontColor : Html.Attribute msg
defaultFontColor =
    Html.Attributes.style "color" "rgb(240,240,240)"


getState :
    Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
getState instructions =
    case instructions of
        NextStep _ _ instructions_ ->
            getState instructions_

        AndThen _ instructions_ ->
            getState instructions_

        Start state ->
            state


getTestName : Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel -> String
getTestName instructions =
    case instructions of
        NextStep _ _ instructions_ ->
            getTestName instructions_

        AndThen _ instructions_ ->
            getTestName instructions_

        Start state ->
            state.testName


modelView :
    RegularDict.Dict (List String) CollapsedField
    -> EventFrontend frontendModel
    -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
modelView collapsedFields frontend =
    case frontend.cachedElmValue of
        Just elmValue ->
            Effect.TreeView.treeView treeViewConfig 0 [] collapsedFields elmValue

        Nothing ->
            Html.text "Failed to show frontend model"


treeViewConfig : Effect.TreeView.MsgConfig (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
treeViewConfig =
    { pressedExpandField = PressedExpandField
    , pressedCollapseField = PressedCollapseField
    }


toElmValue :
    FrontendApp toBackend frontendMsg frontendModel toFrontend
    -> BackendApp toBackend toFrontend backendMsg backendModel
    -> backendModel
    -> EventFrontend frontendModel
    -> Maybe ElmValue
toElmValue frontendApp backendApp backendModel testStep =
    { sessionId = Effect.Lamdera.sessionIdToString testStep.sessionId
    , url = Url.toString testStep.url
    , frontendSubscriptions = frontendApp.subscriptions testStep.model
    , backendSubscriptions = backendApp.subscriptions backendModel
    , frontendModel = testStep.model
    , backendModel = backendModel
    }
        --|> Debug.toString
        --|> DebugParser.parseWithOptionalTag
        --|> Result.toMaybe
        --|> Maybe.map (\a -> refineElmValue a.value)
        |> DebugParser.valueToElmValue
        |> Just


refineElmValue : ElmValue -> ElmValue
refineElmValue value =
    case value of
        Plain _ ->
            value

        Expandable expandableValue ->
            (case expandableValue of
                ElmSequence sequenceType elmValues ->
                    List.map refineElmValue elmValues |> ElmSequence sequenceType

                ElmType variant elmValues ->
                    case ( variant, elmValues ) of
                        ( "D", [ Expandable (ElmSequence SeqList list) ] ) ->
                            List.filterMap
                                (\a ->
                                    case a of
                                        Expandable (ElmSequence SeqTuple [ key, value2 ]) ->
                                            Just ( refineElmValue key, refineElmValue value2 )

                                        _ ->
                                            Nothing
                                )
                                list
                                |> ElmDict

                        _ ->
                            ElmType variant (List.map refineElmValue elmValues)

                ElmRecord fields ->
                    List.map (\( field, value2 ) -> ( field, refineElmValue value2 )) fields |> ElmRecord

                ElmDict list ->
                    List.map (\( key, value2 ) -> ( refineElmValue key, refineElmValue value2 )) list
                        |> ElmDict
            )
                |> Expandable


modelDiffView :
    RegularDict.Dict (List String) CollapsedField
    -> EventFrontend frontendModel
    -> EventFrontend frontendModel
    -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
modelDiffView collapsedFields frontend previousFrontend =
    case ( frontend.cachedElmValue, previousFrontend.cachedElmValue ) of
        ( Just ok, Just previous ) ->
            Effect.TreeView.treeViewDiff treeViewConfig 0 [] collapsedFields previous ok

        _ ->
            Html.text "Failed to show frontend model"


slider : Int -> Array a -> Int -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
slider windowWidth steps stepIndex =
    let
        totalSteps =
            Array.length steps
    in
    Html.input
        [ Html.Attributes.type_ "range"
        , Html.Attributes.min "0"
        , Html.Attributes.max (String.fromInt totalSteps)
        , Html.Attributes.value (String.fromInt stepIndex)
        , Html.Attributes.step "1"
        , Html.Attributes.style "width" (String.fromInt (min (windowWidth // 2) (totalSteps * 10)) ++ "px")
        , Html.Events.onInput ChangedEventSlider
        , Html.Attributes.list "slider-ticks"
        , Html.Attributes.style "padding" "4px"
        ]
        (if windowWidth < totalSteps * 2 then
            []

         else
            [ List.range 0 (totalSteps - 1)
                |> List.map (\index -> Html.option [ Html.Attributes.value (String.fromInt index) ] [])
                |> Html.datalist [ Html.Attributes.id "slider-ticks" ]
            ]
        )


currentStepText :
    Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
currentStepText currentStep testView_ =
    Html.div
        [ Html.Attributes.style "padding" "4px" ]
        [ Html.text
            (" "
                ++ String.fromInt (testView_.stepIndex + 1)
                ++ "/"
                ++ String.fromInt (Array.length testView_.steps)
                ++ (" "
                        ++ (case currentStep.eventType of
                                TestEvent name ->
                                    name

                                ToBackendEvent toBackend command ->
                                    "ToBackend"

                                ToFrontendEvent sessionId clientId toFrontend command ->
                                    "ToFrontend"

                                BackendMsgEvent backendMsg command ->
                                    "BackendMsg"

                                FrontendMsgEvent sessionId clientId frontendMsg command ->
                                    "FrontendMsg"
                           )
                   )
            )
        ]


testView :
    Int
    -> Instructions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> List (Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel))
testView windowWidth instructions testView_ =
    let
        state : State toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        state =
            getState instructions
    in
    case Array.get testView_.stepIndex testView_.steps of
        Just currentStep ->
            if testView_.showModel then
                let
                    maybePreviousFrontend : Maybe (EventFrontend frontendModel)
                    maybePreviousFrontend =
                        case Array.get (testView_.stepIndex - 1) testView_.steps of
                            Just previousStep ->
                                Maybe.andThen (\clientId -> Dict.get clientId previousStep.frontends) testView_.clientId

                            Nothing ->
                                Nothing
                in
                [ Html.div
                    [ Html.Attributes.style "width" "100%"
                    , Html.Attributes.style "min-height" "100vh"
                    , darkBackground
                    , defaultFontColor
                    , Html.Attributes.style "font-family" "arial"
                    , Html.Attributes.style "white-space" "pre"
                    ]
                    [ Html.div
                        []
                        [ Html.div
                            []
                            [ overlayButton PressedBackToOverview "Close"
                            , Html.div [ Html.Attributes.style "display" "inline-block", Html.Attributes.style "padding" "4px" ] []
                            , overlayButton PressedStepBackward "Previous"
                            , overlayButton PressedStepForward "Next step"
                            , overlayButton PressedHideModel "Hide model"
                            ]
                        , Html.Lazy.lazy3 slider windowWidth testView_.steps testView_.stepIndex
                        , currentStepText currentStep testView_
                        , frontendSelection currentStep testView_
                        ]
                    , Html.div
                        [ Html.Attributes.style "font-size" "14px", Html.Attributes.style "padding" "4px" ]
                        [ case Maybe.andThen (\clientId -> Dict.get clientId currentStep.frontends) testView_.clientId of
                            Just frontend ->
                                case maybePreviousFrontend of
                                    Just previousFrontend ->
                                        Html.Lazy.lazy3 modelDiffView testView_.collapsedFields frontend previousFrontend

                                    Nothing ->
                                        Html.Lazy.lazy2 modelView testView_.collapsedFields frontend

                            Nothing ->
                                Html.text ""
                        ]
                    ]
                ]

            else
                [ testOverlay windowWidth testView_ currentStep
                , case testView_.clientId of
                    Just clientId ->
                        case Dict.get clientId currentStep.frontends of
                            Just frontend ->
                                state.frontendApp.view frontend.model |> .body |> Html.div [] |> Html.map (\_ -> NoOp)

                            Nothing ->
                                Html.div
                                    [ Html.Attributes.style "text-align" "center"
                                    , Html.Attributes.style "margin-top" "200px"
                                    , Html.Attributes.style "font-size" "18px"
                                    , Html.Attributes.style "font-weight" "bold"
                                    , Html.Attributes.style "color" "rgb(100, 100, 100)"
                                    , Html.Attributes.style "font-family" "arial"
                                    ]
                                    [ Html.text (Effect.Lamdera.clientIdToString clientId ++ " not found") ]

                    Nothing ->
                        Html.text ""
                ]

        Nothing ->
            [ Html.text "Step not found" ]


testOverlay :
    Int
    -> TestView toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Event toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Html (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
testOverlay windowWidth testView_ currentStep =
    Html.div
        [ Html.Attributes.style "padding" "4px"
        , Html.Attributes.style "font-family" "arial"
        , Html.Attributes.style "font-size" "14px"
        , defaultFontColor
        , Html.Attributes.style "position" "fixed"
        , darkBackground
        , Html.Attributes.style "z-index" "9999"
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
            , overlayButton PressedShowModel "Show model"
            ]
        , Html.Lazy.lazy3 slider windowWidth testView_.steps testView_.stepIndex
        , currentStepText currentStep testView_
        , frontendSelection currentStep testView_
        , Html.div
            [ Html.Attributes.style "color" "rgb(200, 10, 10)"
            ]
            (List.map (testErrorToString >> text) currentStep.testErrors)
        ]


frontendSelection currentStep testView_ =
    let
        frontends =
            Dict.toList currentStep.frontends
    in
    if List.isEmpty frontends then
        text "No frontends have connected"

    else
        Html.div
            [ Html.Attributes.style "padding" "4px"
            , Html.Attributes.style "display" "inline-block"
            ]
            [ Html.text "Frontends:" ]
            :: List.map
                (\( clientId, _ ) ->
                    Html.div
                        [ Html.Attributes.style "padding-right" "4px"
                        , Html.Attributes.style "display" "inline-block"
                        ]
                        [ overlaySelectButton
                            (Just clientId == testView_.clientId)
                            (SelectedFrontend clientId)
                            (Effect.Lamdera.clientIdToString clientId)
                        ]
                )
                frontends
            |> Html.div []


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
        , subscriptions = viewerSubscriptions
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        }


viewerSubscriptions :
    Model toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
    -> Sub (Msg toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
viewerSubscriptions _ =
    Sub.batch
        [ Browser.Events.onKeyDown
            (Json.Decode.field "key" Json.Decode.string
                |> Json.Decode.andThen
                    (\key ->
                        if key == "ArrowLeft" then
                            PressedArrowKey ArrowLeft |> Json.Decode.succeed

                        else if key == "ArrowRight" then
                            PressedArrowKey ArrowRight |> Json.Decode.succeed

                        else
                            Json.Decode.fail ""
                    )
            )
        , Browser.Events.onResize GotWindowSize
        ]


type ArrowKey
    = ArrowLeft
    | ArrowRight


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
        , subscriptions = viewerSubscriptions
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        }


{-| Add a file containing binary data to your tests.

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


{-| Add a file containing text data to your tests.

    import Effect.Test

    main =
        Effect.Test.viewerWith
            (\text jsonData ->
                [{- End to end tests go here -}]
            )
            |> Effect.Test.addStringFile "/test.txt"
            |> Effect.Test.addStringFile "/data.json"
            |> Effect.Test.startViewer

-}
addStringFile : String -> ViewerWith (String -> b) -> ViewerWith b
addStringFile file model =
    { cmds =
        Task.andThen
            (\tests ->
                Http.task
                    { method = "GET"
                    , headers = []
                    , body = Http.emptyBody
                    , url = file
                    , resolver =
                        Http.stringResolver
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
