module Effect.Lamdera exposing
    ( frontend, backend, sendToBackend, sendToFrontend, sendToFrontends, broadcast, onConnect, onDisconnect, ClientId, clientIdToString, clientIdFromString, SessionId, sessionIdToString, sessionIdFromString
    , toCmd
    )

{-| backend

@docs frontend, backend, sendToBackend, sendToFrontend, sendToFrontends, broadcast, onConnect, onDisconnect, ClientId, clientIdToString, clientIdFromString, SessionId, sessionIdToString, sessionIdFromString


# Temporary integration

@docs toCmd

-}

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Bytes.Encode
import Duration
import Effect.Browser.Navigation
import Effect.Command exposing (BackendOnly, Command, FrontendOnly)
import Effect.Http
import Effect.Internal exposing (File(..), NavigationKey(..))
import Effect.Subscription exposing (Subscription)
import Effect.WebGL.Texture
import File
import File.Download
import File.Select
import Http
import Lamdera
import Process
import Task
import Time
import Url
import WebGLFix.Texture


{-| Create a Lamdera frontend application
-}
frontend :
    (toBackend -> Cmd frontendMsg)
    ->
        { init : Url.Url -> Effect.Browser.Navigation.Key -> ( model, Command FrontendOnly toBackend frontendMsg )
        , view : model -> Browser.Document frontendMsg
        , update : frontendMsg -> model -> ( model, Command FrontendOnly toBackend frontendMsg )
        , updateFromBackend : toFrontend -> model -> ( model, Command FrontendOnly toBackend frontendMsg )
        , subscriptions : model -> Subscription FrontendOnly frontendMsg
        , onUrlRequest : Browser.UrlRequest -> frontendMsg
        , onUrlChange : Url.Url -> frontendMsg
        }
    ->
        { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd frontendMsg )
        , view : model -> Browser.Document frontendMsg
        , update : frontendMsg -> model -> ( model, Cmd frontendMsg )
        , updateFromBackend : toFrontend -> model -> ( model, Cmd frontendMsg )
        , subscriptions : model -> Sub frontendMsg
        , onUrlRequest : Browser.UrlRequest -> frontendMsg
        , onUrlChange : Url.Url -> frontendMsg
        }
frontend toBackend userApp =
    { init =
        \url navigationKey ->
            userApp.init url (Effect.Internal.RealNavigationKey navigationKey |> Effect.Browser.Navigation.fromInternalKey)
                |> Tuple.mapSecond (toCmd (\_ -> Cmd.none) (\_ _ -> Cmd.none) toBackend)
    , view = userApp.view
    , update =
        \msg model ->
            userApp.update msg model
                |> Tuple.mapSecond (toCmd (\_ -> Cmd.none) (\_ _ -> Cmd.none) toBackend)
    , updateFromBackend =
        \msg model ->
            userApp.updateFromBackend msg model
                |> Tuple.mapSecond (toCmd (\_ -> Cmd.none) (\_ _ -> Cmd.none) toBackend)
    , subscriptions = userApp.subscriptions >> toSub
    , onUrlRequest = userApp.onUrlRequest
    , onUrlChange = userApp.onUrlChange
    }


{-| Create a Lamdera backend application
-}
backend :
    (toFrontend -> Cmd backendMsg)
    -> (String -> toFrontend -> Cmd backendMsg)
    ->
        { init : ( backendModel, Command BackendOnly toFrontend backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
        , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
        , subscriptions : backendModel -> Subscription BackendOnly backendMsg
        }
    ->
        { init : ( backendModel, Cmd backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
        , updateFromFrontend : String -> String -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
        , subscriptions : backendModel -> Sub backendMsg
        }
backend broadcastCmd toFrontend userApp =
    { init = userApp.init |> Tuple.mapSecond (toCmd broadcastCmd toFrontend (\_ -> Cmd.none))
    , update = \msg model -> userApp.update msg model |> Tuple.mapSecond (toCmd broadcastCmd toFrontend (\_ -> Cmd.none))
    , updateFromFrontend =
        \sessionId clientId msg model ->
            userApp.updateFromFrontend
                (sessionIdFromString sessionId)
                (clientIdFromString clientId)
                msg
                model
                |> Tuple.mapSecond (toCmd broadcastCmd toFrontend (\_ -> Cmd.none))
    , subscriptions = userApp.subscriptions >> toSub
    }


{-| Send a toBackend msg to the Backend
-}
sendToBackend : toBackend -> Command FrontendOnly toBackend frontendMsg
sendToBackend =
    Effect.Internal.SendToBackend


{-| Send a toFrontend msg to the Frontend
-}
sendToFrontend : ClientId -> toFrontend -> Command BackendOnly toFrontend backendMsg
sendToFrontend client toFrontend =
    Effect.Internal.SendToFrontend (clientIdToString client |> Effect.Internal.ClientId) toFrontend


{-| Send a toFrontend msg to all the frontends that have a given SessionId.
-}
sendToFrontends : SessionId -> toFrontend -> Command BackendOnly toFrontend backendMsg
sendToFrontends sessionId toFrontend =
    Effect.Internal.SendToFrontends (sessionIdToString sessionId |> Effect.Internal.SessionId) toFrontend


{-| Send a toFrontend msg to all currently connected clients
-}
broadcast : toFrontend -> Command BackendOnly toFrontend backendMsg
broadcast =
    Effect.Internal.Broadcast


{-| Subscribe to Frontend client connected events
-}
onConnect : (SessionId -> ClientId -> backendMsg) -> Subscription BackendOnly backendMsg
onConnect msg =
    Effect.Internal.OnConnect
        (\(Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId) ->
            msg (sessionIdFromString sessionId) (clientIdFromString clientId)
        )


{-| Subscribe to Frontend client disconnected events
-}
onDisconnect : (SessionId -> ClientId -> backendMsg) -> Subscription BackendOnly backendMsg
onDisconnect msg =
    Effect.Internal.OnDisconnect
        (\(Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId) ->
            msg (sessionIdFromString sessionId) (clientIdFromString clientId)
        )


{-| -}
type ClientId
    = ClientId String


{-| -}
type SessionId
    = SessionId String


{-| -}
sessionIdFromString : String -> SessionId
sessionIdFromString =
    SessionId


{-| -}
sessionIdToString : SessionId -> String
sessionIdToString (SessionId sessionId) =
    sessionId


{-| -}
clientIdFromString : String -> ClientId
clientIdFromString =
    ClientId


{-| -}
clientIdToString : ClientId -> String
clientIdToString (ClientId clientId) =
    clientId


{-| Escape hatch for converting a `Command` to a regular `Cmd` in non-test code.
-}
toCmd : (toMsg -> Cmd msg) -> (String -> toMsg -> Cmd msg) -> (toMsg -> Cmd msg) -> Command restriction toMsg msg -> Cmd msg
toCmd broadcastCmd toFrontendCmd toBackendCmd effect =
    case effect of
        Effect.Internal.Batch effects ->
            List.map (toCmd broadcastCmd toFrontendCmd toBackendCmd) effects |> Cmd.batch

        Effect.Internal.None ->
            Cmd.none

        Effect.Internal.SendToBackend toBackend ->
            toBackendCmd toBackend

        Effect.Internal.NavigationPushUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key string

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationReplaceUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key string

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationLoad url ->
            Browser.Navigation.load url

        Effect.Internal.NavigationBack navigationKey int ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.back key int

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationForward navigationKey int ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.forward key int

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationReload ->
            Browser.Navigation.reload

        Effect.Internal.NavigationReloadAndSkipCache ->
            Browser.Navigation.reloadAndSkipCache

        Effect.Internal.Task simulatedTask ->
            toTask simulatedTask
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok ok ->
                                ok

                            Err err ->
                                err
                    )

        Effect.Internal.Port _ portFunction value ->
            portFunction value

        Effect.Internal.SendToFrontend (Effect.Internal.ClientId clientId) toFrontend ->
            toFrontendCmd clientId toFrontend

        Effect.Internal.SendToFrontends (Effect.Internal.SessionId sessionId) toFrontend ->
            toFrontendCmd sessionId toFrontend

        Effect.Internal.FileDownloadUrl { href } ->
            File.Download.url href

        Effect.Internal.FileDownloadString { name, mimeType, content } ->
            File.Download.string name mimeType content

        Effect.Internal.FileDownloadBytes { name, mimeType, content } ->
            File.Download.bytes name mimeType content

        Effect.Internal.FileSelectFile mimeTypes msg ->
            File.Select.file mimeTypes (RealFile >> msg)

        Effect.Internal.FileSelectFiles mimeTypes msg ->
            File.Select.files mimeTypes (\file restOfFiles -> msg (RealFile file) (List.map RealFile restOfFiles))

        Effect.Internal.Broadcast toMsg ->
            broadcastCmd toMsg

        Effect.Internal.HttpCancel string ->
            Http.cancel string

        Effect.Internal.Passthrough cmd ->
            cmd


httpHelper httpRequest resolver =
    Http.task
        { method = httpRequest.method
        , headers = List.map (\( key, value ) -> Http.header key value) httpRequest.headers
        , url = httpRequest.url
        , body =
            case httpRequest.body of
                Effect.Internal.EmptyBody ->
                    Http.emptyBody

                Effect.Internal.StringBody { contentType, content } ->
                    Http.stringBody contentType content

                Effect.Internal.JsonBody value ->
                    Http.jsonBody value

                Effect.Internal.MultipartBody httpParts ->
                    List.map
                        (\part ->
                            case part of
                                Effect.Internal.StringPart a b ->
                                    Http.stringPart a b

                                Effect.Internal.FilePart a b ->
                                    case b of
                                        Effect.Internal.RealFile file ->
                                            Http.filePart a file

                                        Effect.Internal.MockFile _ ->
                                            Http.stringPart "" ""

                                Effect.Internal.BytesPart key mimeType content ->
                                    Http.bytesPart key mimeType content
                        )
                        httpParts
                        |> Http.multipartBody

                Effect.Internal.BytesBody a b ->
                    Http.bytesBody a b

                Effect.Internal.FileBody file ->
                    case file of
                        Effect.Internal.RealFile realFile ->
                            Http.fileBody realFile

                        MockFile _ ->
                            Http.emptyBody
        , resolver = resolver Ok
        , timeout = Maybe.map Duration.inMilliseconds httpRequest.timeout
        }
        |> Task.andThen (\response -> httpRequest.onRequestComplete response |> toTask)


toTask : Effect.Internal.Task restriction x b -> Task.Task x b
toTask simulatedTask =
    case simulatedTask of
        Effect.Internal.Succeed a ->
            Task.succeed a

        Effect.Internal.Fail x ->
            Task.fail x

        Effect.Internal.HttpStringTask httpRequest ->
            httpHelper httpRequest Http.stringResolver

        Effect.Internal.HttpBytesTask httpRequest ->
            httpHelper httpRequest Http.bytesResolver

        Effect.Internal.SleepTask duration function ->
            Process.sleep (Duration.inMilliseconds duration)
                |> Task.andThen (\() -> toTask (function ()))

        Effect.Internal.TimeNow gotTime ->
            Time.now |> Task.andThen (\time -> toTask (gotTime time))

        Effect.Internal.TimeHere gotTimeZone ->
            Time.here |> Task.andThen (\timeZone -> toTask (gotTimeZone timeZone))

        Effect.Internal.TimeGetZoneName gotTimeZoneName ->
            Time.getZoneName |> Task.andThen (\time -> toTask (gotTimeZoneName time))

        Effect.Internal.SetViewport x y function ->
            Browser.Dom.setViewport x y |> Task.andThen (\() -> toTask (function ()))

        Effect.Internal.GetViewport function ->
            Browser.Dom.getViewport |> Task.andThen (\viewport -> toTask (function viewport))

        Effect.Internal.GetElement string function ->
            Browser.Dom.getElement string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.Focus string msg ->
            Browser.Dom.focus string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.Blur string msg ->
            Browser.Dom.blur string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.GetViewportOf string msg ->
            Browser.Dom.getViewportOf string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.SetViewportOf string x y msg ->
            Browser.Dom.setViewportOf string x y
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.FileToString file function ->
            case file of
                RealFile file_ ->
                    File.toString file_ |> Task.andThen (\result -> toTask (function result))

                MockFile { content } ->
                    Task.succeed content |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.FileToBytes file function ->
            case file of
                RealFile file_ ->
                    File.toBytes file_ |> Task.andThen (\result -> toTask (function result))

                MockFile { content } ->
                    Bytes.Encode.string content
                        |> Bytes.Encode.encode
                        |> Task.succeed
                        |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.FileToUrl file function ->
            case file of
                RealFile file_ ->
                    File.toUrl file_ |> Task.andThen (\result -> toTask (function result))

                MockFile { content } ->
                    -- This isn't the correct behavior but it should be okay as MockFile should never be used here.
                    Task.succeed content |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.LoadTexture options string function ->
            let
                convertWrap wrap =
                    case wrap of
                        Effect.Internal.Repeat ->
                            WebGLFix.Texture.repeat

                        Effect.Internal.ClampToEdge ->
                            WebGLFix.Texture.clampToEdge

                        Effect.Internal.MirroredRepeat ->
                            WebGLFix.Texture.mirroredRepeat
            in
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
                string
                |> Task.map (Effect.Internal.RealTexture >> Ok)
                |> Task.onError (Err >> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))


toSub : Subscription restriction msg -> Sub msg
toSub sub =
    case sub of
        Effect.Internal.SubBatch subs ->
            List.map toSub subs |> Sub.batch

        Effect.Internal.SubNone ->
            Sub.none

        Effect.Internal.TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        Effect.Internal.OnAnimationFrame msg ->
            Browser.Events.onAnimationFrame msg

        Effect.Internal.OnAnimationFrameDelta msg ->
            Browser.Events.onAnimationFrameDelta (Duration.milliseconds >> msg)

        Effect.Internal.OnKeyPress decoder ->
            Browser.Events.onKeyPress decoder

        Effect.Internal.OnKeyDown decoder ->
            Browser.Events.onKeyDown decoder

        Effect.Internal.OnKeyUp decoder ->
            Browser.Events.onKeyUp decoder

        Effect.Internal.OnClick decoder ->
            Browser.Events.onClick decoder

        Effect.Internal.OnMouseMove decoder ->
            Browser.Events.onMouseMove decoder

        Effect.Internal.OnMouseDown decoder ->
            Browser.Events.onMouseDown decoder

        Effect.Internal.OnMouseUp decoder ->
            Browser.Events.onMouseUp decoder

        Effect.Internal.OnVisibilityChange msg ->
            Browser.Events.onVisibilityChange
                (\visibility ->
                    case visibility of
                        Browser.Events.Visible ->
                            msg Effect.Internal.Visible

                        Browser.Events.Hidden ->
                            msg Effect.Internal.Hidden
                )

        Effect.Internal.OnResize msg ->
            Browser.Events.onResize msg

        Effect.Internal.SubPort _ portFunction _ ->
            portFunction

        Effect.Internal.OnConnect msg ->
            Lamdera.onConnect
                (\sessionId clientId ->
                    msg (Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId)
                )

        Effect.Internal.OnDisconnect msg ->
            Lamdera.onDisconnect
                (\sessionId clientId ->
                    msg (Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId)
                )

        Effect.Internal.HttpTrack string function ->
            Http.track string function
