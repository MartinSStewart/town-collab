port module Ports exposing (audioPortFromJS, audioPortToJS, copyToClipboard, getLocalStorage, gotLocalStorage, martinsstewart_elm_device_pixel_ratio_from_js, martinsstewart_elm_device_pixel_ratio_to_js, mouse_leave, readFromClipboardRequest, readFromClipboardResponse, setLocalStorage, user_agent_from_js, user_agent_to_js)

import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
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


port supermario_read_from_clipboard_to_js : Json.Encode.Value -> Cmd msg


readFromClipboardRequest : Command FrontendOnly toMsg msg
readFromClipboardRequest =
    Command.sendToJs
        "supermario_read_from_clipboard_to_js"
        supermario_read_from_clipboard_to_js
        Json.Encode.null


port supermario_read_from_clipboard_from_js : (Json.Decode.Value -> msg) -> Sub msg


readFromClipboardResponse : (String -> msg) -> Subscription FrontendOnly msg
readFromClipboardResponse msg =
    Subscription.fromJs
        "supermario_read_from_clipboard_from_js"
        supermario_read_from_clipboard_from_js
        (\value ->
            Json.Decode.decodeValue Json.Decode.string value
                |> Result.withDefault ""
                |> msg
        )