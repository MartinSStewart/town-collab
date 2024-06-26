port module Ports exposing
    ( audioPortFromJS
    , audioPortToJS
    , copyToClipboard
    , getDevicePixelRatio
    , getLocalStorage
    , gotDevicePixelRatio
    , gotLocalStorage
    , mouse_leave
    , onPasteEvent
    , openNewTab
    , setLocalStorage
    , user_agent_from_js
    , user_agent_to_js
    )

import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Hyperlink exposing (Hyperlink)
import Json.Decode
import Json.Encode
import Serialize exposing (Codec)
import Sound
import Types exposing (UserSettings)


port martinsstewart_elm_device_pixel_ratio_from_js : (Json.Decode.Value -> msg) -> Sub msg


port martinsstewart_elm_device_pixel_ratio_to_js : Json.Encode.Value -> Cmd msg


port user_agent_to_js : Json.Encode.Value -> Cmd msg


port user_agent_from_js : (Json.Decode.Value -> msg) -> Sub msg


port audioPortToJS : Json.Encode.Value -> Cmd msg


port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg


port supermario_copy_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


port mouse_leave : (Json.Decode.Value -> msg) -> Sub msg


port get_local_storage : Json.Encode.Value -> Cmd msg


port got_local_storage : (Json.Decode.Value -> msg) -> Sub msg


port set_local_storage : Json.Encode.Value -> Cmd msg


port open_new_tab_to_js : Json.Encode.Value -> Cmd msg


port paste_event_from_js : (Json.Decode.Value -> msg) -> Sub msg


onPasteEvent : (String -> msg) -> Subscription.Subscription FrontendOnly msg
onPasteEvent msg =
    Subscription.fromJs
        "paste_event_from_js"
        paste_event_from_js
        (\value ->
            Json.Decode.decodeValue Json.Decode.string value
                |> Result.withDefault ""
                |> msg
        )


openNewTab : Hyperlink -> Command FrontendOnly toMsg msg
openNewTab hyperlink =
    Command.sendToJs "open_new_tab_to_js" open_new_tab_to_js (Json.Encode.string (Hyperlink.toUrl hyperlink))


getDevicePixelRatio : Command FrontendOnly toMsg msg
getDevicePixelRatio =
    Command.sendToJs "martinsstewart_elm_device_pixel_ratio_to_js" martinsstewart_elm_device_pixel_ratio_to_js Json.Encode.null


gotDevicePixelRatio : (Float -> msg) -> Subscription.Subscription FrontendOnly msg
gotDevicePixelRatio msg =
    Subscription.fromJs
        "martinsstewart_elm_device_pixel_ratio_from_js"
        martinsstewart_elm_device_pixel_ratio_from_js
        (\value ->
            Json.Decode.decodeValue Json.Decode.float value
                |> Result.withDefault 1
                |> msg
        )


getLocalStorage : Command FrontendOnly toMsg msg
getLocalStorage =
    Command.sendToJs
        "get_local_storage"
        get_local_storage
        Json.Encode.null


gotLocalStorage : (UserSettings -> msg) -> Subscription FrontendOnly msg
gotLocalStorage sub =
    Subscription.fromJs
        "got_local_storage"
        got_local_storage
        (\value ->
            case Serialize.decodeFromJson userSettingsCodec value of
                Ok ok ->
                    sub ok

                Err _ ->
                    sub { musicVolume = Sound.maxVolume, soundEffectVolume = Sound.maxVolume }
        )


userSettingsCodec : Codec e UserSettings
userSettingsCodec =
    Serialize.record UserSettings
        |> Serialize.field .musicVolume Serialize.byte
        |> Serialize.field .soundEffectVolume Serialize.byte
        |> Serialize.finishRecord


setLocalStorage : UserSettings -> Command FrontendOnly toMsg msg
setLocalStorage userSettings =
    Command.sendToJs
        "set_local_storage"
        set_local_storage
        (Serialize.encodeToJson userSettingsCodec userSettings)


copyToClipboard : String -> Command FrontendOnly toMsg msg
copyToClipboard text =
    Command.sendToJs
        "supermario_copy_to_clipboard_to_js"
        supermario_copy_to_clipboard_to_js
        (Json.Encode.string text)
