module Effect.Internal exposing
    ( BackendOnly
    , Bigger(..)
    , BrowserDomError(..)
    , ClientId(..)
    , Command(..)
    , File(..)
    , FrontendOnly
    , HttpBody(..)
    , HttpPart(..)
    , HttpRequest
    , NavigationKey(..)
    , Resize(..)
    , SessionId(..)
    , Smaller(..)
    , Subscription(..)
    , Task(..)
    , Texture(..)
    , Visibility(..)
    , Wrap(..)
    , andThen
    , taskMap
    , taskMapError
    )

import Browser.Dom
import Browser.Navigation
import Bytes exposing (Bytes)
import Duration exposing (Duration)
import File
import Http
import Json.Decode
import Json.Encode
import Time
import WebGLFix.Texture


type SessionId
    = SessionId String


type ClientId
    = ClientId String


type FrontendOnly
    = FrontendOnly Never


type BackendOnly
    = BackendOnly Never


type Subscription restriction msg
    = SubBatch (List (Subscription restriction msg))
    | SubNone
    | TimeEvery Duration (Time.Posix -> msg)
    | OnAnimationFrame (Time.Posix -> msg)
    | OnAnimationFrameDelta (Duration -> msg)
    | OnKeyPress (Json.Decode.Decoder msg)
    | OnKeyDown (Json.Decode.Decoder msg)
    | OnKeyUp (Json.Decode.Decoder msg)
    | OnClick (Json.Decode.Decoder msg)
    | OnMouseMove (Json.Decode.Decoder msg)
    | OnMouseDown (Json.Decode.Decoder msg)
    | OnMouseUp (Json.Decode.Decoder msg)
    | OnResize (Int -> Int -> msg)
    | OnVisibilityChange (Visibility -> msg)
    | SubPort String (Sub msg) (Json.Decode.Value -> msg)
    | OnConnect (SessionId -> ClientId -> msg)
    | OnDisconnect (SessionId -> ClientId -> msg)
    | HttpTrack String (Http.Progress -> msg)


type Visibility
    = Visible
    | Hidden


type Command restriction toMsg msg
    = Batch (List (Command restriction toMsg msg))
    | None
    | SendToBackend toMsg
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationBack NavigationKey Int
    | NavigationForward NavigationKey Int
    | NavigationLoad String
    | NavigationReload
    | NavigationReloadAndSkipCache
    | Task (Task restriction msg msg)
    | Port String (Json.Encode.Value -> Cmd msg) Json.Encode.Value
    | SendToFrontend ClientId toMsg
    | SendToFrontends SessionId toMsg
    | Broadcast toMsg
    | FileDownloadUrl { href : String }
    | FileDownloadString { name : String, mimeType : String, content : String }
    | FileDownloadBytes { name : String, mimeType : String, content : Bytes }
    | FileSelectFile (List String) (File -> msg)
    | FileSelectFiles (List String) (File -> List File -> msg)
    | HttpCancel String
    | Passthrough (Cmd msg)


type Task restriction x a
    = Succeed a
    | Fail x
    | HttpStringTask (HttpRequest String restriction x a)
    | HttpBytesTask (HttpRequest Bytes restriction x a)
    | SleepTask Duration (() -> Task restriction x a)
    | TimeNow (Time.Posix -> Task restriction x a)
    | TimeHere (Time.Zone -> Task restriction x a)
    | TimeGetZoneName (Time.ZoneName -> Task restriction x a)
    | Focus String (Result BrowserDomError () -> Task restriction x a)
    | Blur String (Result BrowserDomError () -> Task restriction x a)
    | GetViewport (Browser.Dom.Viewport -> Task restriction x a)
    | SetViewport Float Float (() -> Task restriction x a)
    | GetViewportOf String (Result BrowserDomError Browser.Dom.Viewport -> Task restriction x a)
    | SetViewportOf String Float Float (Result BrowserDomError () -> Task restriction x a)
    | GetElement String (Result BrowserDomError Browser.Dom.Element -> Task restriction x a)
    | FileToString File (String -> Task restriction x a)
    | FileToBytes File (Bytes -> Task restriction x a)
    | FileToUrl File (String -> Task restriction x a)
    | LoadTexture LoadTextureOptions String (Result WebGLFix.Texture.Error Texture -> Task restriction x a)


type Texture
    = RealTexture WebGLFix.Texture.Texture
    | MockTexture Int Int


type Bigger
    = Bigger


type Smaller
    = Smaller


type Wrap
    = Repeat
    | ClampToEdge
    | MirroredRepeat


type Resize a
    = Linear
    | Nearest
    | NearestMipmapNearest
    | LinearMipmapNearest
    | NearestMipmapLinear
    | LinearMipmapLinear


type alias LoadTextureOptions =
    { magnify : Resize Bigger
    , minify : Resize Smaller
    , horizontalWrap : Wrap
    , verticalWrap : Wrap
    , flipY : Bool
    , premultiplyAlpha : Bool
    }


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type BrowserDomError
    = BrowserDomNotFound String


type File
    = RealFile File.File
    | MockFile { name : String, mimeType : String, content : String, lastModified : Time.Posix }


type alias HttpRequest data restriction x a =
    { method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    , onRequestComplete : Http.Response data -> Task restriction x a
    , timeout : Maybe Duration
    , isRisky : Bool
    }


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


type HttpPart
    = StringPart String String
    | FilePart String File
    | BytesPart String String Bytes


taskMap : (a -> b) -> Task restriction x a -> Task restriction x b
taskMap f =
    andThen (f >> Succeed)


andThen : (a -> Task restriction x b) -> Task c x a -> Task restriction x b
andThen f task =
    case task of
        Succeed a ->
            f a

        Fail x ->
            Fail x

        HttpStringTask request ->
            HttpStringTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> andThen f
                , timeout = request.timeout
                , isRisky = request.isRisky
                }

        HttpBytesTask request ->
            HttpBytesTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> andThen f
                , timeout = request.timeout
                , isRisky = request.isRisky
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> andThen f)

        TimeNow gotTime ->
            TimeNow (gotTime >> andThen f)

        TimeHere gotTimeZone ->
            TimeHere (gotTimeZone >> andThen f)

        TimeGetZoneName gotTimeZoneName ->
            TimeGetZoneName (gotTimeZoneName >> andThen f)

        SetViewport x y function ->
            SetViewport x y (function >> andThen f)

        GetViewport function ->
            GetViewport (function >> andThen f)

        GetElement string function ->
            GetElement string (function >> andThen f)

        Focus string function ->
            Focus string (function >> andThen f)

        Blur string function ->
            Blur string (function >> andThen f)

        GetViewportOf string function ->
            GetViewportOf string (function >> andThen f)

        SetViewportOf string x y function ->
            SetViewportOf string x y (function >> andThen f)

        FileToString file function ->
            FileToString file (function >> andThen f)

        FileToBytes file function ->
            FileToBytes file (function >> andThen f)

        FileToUrl file function ->
            FileToUrl file (function >> andThen f)

        LoadTexture loadTextureOptions string function ->
            LoadTexture loadTextureOptions string (function >> andThen f)


taskMapError : (x -> y) -> Task restriction x a -> Task restriction y a
taskMapError f task =
    case task of
        Succeed a ->
            Succeed a

        Fail x ->
            Fail (f x)

        HttpStringTask request ->
            HttpStringTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> taskMapError f
                , timeout = request.timeout
                , isRisky = request.isRisky
                }

        HttpBytesTask request ->
            HttpBytesTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> taskMapError f
                , timeout = request.timeout
                , isRisky = request.isRisky
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskMapError f)

        TimeNow gotTime ->
            TimeNow (gotTime >> taskMapError f)

        TimeHere gotTimeZone ->
            TimeHere (gotTimeZone >> taskMapError f)

        TimeGetZoneName gotTimeZoneName ->
            TimeGetZoneName (gotTimeZoneName >> taskMapError f)

        SetViewport x y function ->
            SetViewport x y (function >> taskMapError f)

        GetViewport function ->
            GetViewport (function >> taskMapError f)

        GetElement string function ->
            GetElement string (function >> taskMapError f)

        Focus string function ->
            Focus string (function >> taskMapError f)

        Blur string function ->
            Blur string (function >> taskMapError f)

        GetViewportOf string function ->
            GetViewportOf string (function >> taskMapError f)

        SetViewportOf string x y function ->
            SetViewportOf string x y (function >> taskMapError f)

        FileToString file function ->
            FileToString file (function >> taskMapError f)

        FileToBytes file function ->
            FileToBytes file (function >> taskMapError f)

        FileToUrl file function ->
            FileToUrl file (function >> taskMapError f)

        LoadTexture loadTextureOptions string function ->
            LoadTexture loadTextureOptions string (function >> taskMapError f)
