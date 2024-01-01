module Effect.Snapshot exposing (uploadSnapshots, PercyApiKey(..), Snapshot, PublicFile, Response, Error(..), errorToString)

{-| Upload snapshots to Percy.io for visual regression testing.
You'll need to create an account first in order to get an API key.

@docs uploadSnapshots, PercyApiKey, Snapshot, PublicFile, Response, Error, errorToString

-}

import Base64
import Bytes exposing (Bytes)
import Dict
import Html exposing (Html)
import Http
import Json.Decode exposing (Decoder)
import Json.Encode
import List.Nonempty exposing (Nonempty(..))
import SHA256
import Set exposing (Set)
import Task exposing (Task)
import Test.Html.Internal.ElmHtml.ToString
import Test.Html.Internal.Inert
import Url
import Url.Builder


{-| Name of the snapshot and the html to be placed inside the body tag.
`widths` specify what widths you want the html to be rendered at.
`minimumHeight` is the minimum height in pixels of the rendered html (it will be taller if the html doesn't fit).
If you set `minimumHeight` to Nothing then it's always the default height of the rendered html.
-}
type alias Snapshot msg =
    { name : String, body : List (Html msg), widths : Nonempty Int, minimumHeight : Maybe Int }


{-| Files in your public folder such as `images/profile-image.png` or `favicon.ico`.
-}
type alias PublicFile =
    { filepath : String
    , content : Bytes
    }


htmlToString : Html msg -> Result String String
htmlToString html =
    Test.Html.Internal.Inert.fromHtml html
        |> Result.map
            (Test.Html.Internal.Inert.toElmHtml
                >> Test.Html.Internal.ElmHtml.ToString.nodeToString
            )


{-| Upload snapshots to Percy.io for visual regression testing.
You'll need to create an account first in order to get an API key.

    import Effect.Snapshot exposing (PercyApiKey(..))
    import List.Nonempty exposing (Nonempty(..))
    import MyLogin

    heroBannerBytes =
        ...

    a =
        uploadSnapshots
            { apiKey = PercyApiKey "my api token"
            , gitBranch = "my-feature-branch"
            , gitTargetBranch = "main"
            , snapshots = Nonempty { name = "Login page", html = MyLogin.view } []
            , publicFiles = [ { filepath = "hero-banner.png", content = heroBannerBytes } ]
            }

-}
uploadSnapshots :
    { apiKey : PercyApiKey
    , gitBranch : String
    , gitTargetBranch : String
    , snapshots : Nonempty (Snapshot msg)
    , publicFiles : List PublicFile
    }
    -> Task Error Response
uploadSnapshots { apiKey, gitBranch, gitTargetBranch, snapshots, publicFiles } =
    let
        publicFiles_ : List HashedPublicFile
        publicFiles_ =
            List.map
                (\file ->
                    { contentHash = SHA256.fromBytes file.content
                    , filepath = file.filepath
                    , base64Content = Base64.fromBytes file.content |> Maybe.withDefault ""
                    }
                )
                publicFiles

        snapshotNames : Set String
        snapshotNames =
            List.Nonempty.toList snapshots |> List.map .name |> Set.fromList
    in
    if Set.size snapshotNames /= List.Nonempty.length snapshots then
        Task.fail SnapshotNamesNotUnique

    else
        createBuild
            apiKey
            { attributes =
                { branch = gitBranch
                , targetBranch = gitTargetBranch
                }
            , relationships = { resources = { data = [] } }
            }
            |> Task.andThen
                (\{ data } ->
                    List.Nonempty.toList snapshots
                        |> List.map (uploadSnapshotHelper apiKey data.buildId publicFiles_)
                        |> Task.sequence
                        |> Task.andThen
                            (\filesToUpload ->
                                List.concat filesToUpload
                                    |> List.map (\a -> ( SHA256.toHex a.contentHash, a ))
                                    |> Dict.fromList
                                    |> Dict.toList
                                    |> List.map
                                        (\( _, { contentHash, base64Content } ) ->
                                            uploadResource apiKey data.buildId contentHash base64Content
                                        )
                                    |> Task.sequence
                            )
                        |> Task.andThen (\_ -> finalize apiKey data.buildId)
                )


type alias HashedPublicFile =
    { contentHash : SHA256.Digest, filepath : String, base64Content : String }


uploadSnapshotHelper : PercyApiKey -> BuildId -> List HashedPublicFile -> Snapshot msg -> Task Error (List HashedPublicFile)
uploadSnapshotHelper apiKey buildId publicFiles_ snapshot_ =
    let
        hash : SHA256.Digest
        hash =
            SHA256.fromString htmlString

        bodyContent : String
        bodyContent =
            List.map
                (htmlToString >> Result.withDefault "<div>Something went wrong when converting this Html into a String. Please file a github issue with what the Html looked like.</div>")
                snapshot_.body
                |> String.concat

        htmlString : String
        htmlString =
            """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, minimum-scale=1.0"></head><body>"""
                ++ bodyContent
                ++ "</body></html>"

        filesToUpload =
            List.filter
                (\{ filepath } -> String.contains filepath htmlString)
                publicFiles_
    in
    createSnapshot
        apiKey
        buildId
        { name = snapshot_.name
        , widths = snapshot_.widths
        , minHeight = snapshot_.minimumHeight
        , resources =
            Nonempty
                { id = hash
                , attributes =
                    { resourceUrl = "/index.html"
                    , isRoot = True
                    , mimeType = Just "text/html"
                    }
                }
                (List.map
                    (\{ contentHash, filepath } ->
                        { id = contentHash
                        , attributes =
                            { resourceUrl =
                                List.map Url.percentEncode (String.split "/" filepath)
                                    |> String.join "/"
                                    |> (++) "/"
                            , isRoot = False
                            , mimeType = Nothing
                            }
                        }
                    )
                    filesToUpload
                )
        }
        |> Task.andThen
            (\_ ->
                uploadResource
                    apiKey
                    buildId
                    hash
                    (Base64.fromString htmlString |> Maybe.withDefault "")
                    |> Task.andThen (\_ -> Task.succeed filesToUpload)
            )


type alias SnapshotResource =
    { id : SHA256.Digest
    , attributes :
        { -- resource filepath (probably the filepath that will be used within the webpage)
          resourceUrl : String
        , -- True if this is the html text
          isRoot : Bool
        , mimeType : Maybe String
        }
    }


percyApiDomain : String
percyApiDomain =
    "https://percy.io/api/v1"


uploadResource : PercyApiKey -> BuildId -> SHA256.Digest -> String -> Task Error ()
uploadResource (PercyApiKey apiKey) (BuildId buildId) hash content =
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Token " ++ apiKey) ]
        , url = Url.Builder.crossOrigin percyApiDomain [ "builds", buildId, "resources" ] []
        , body = Http.jsonBody (encodeUploadResource hash content)
        , resolver = Http.stringResolver (resolver (Json.Decode.succeed ()))
        , timeout = Nothing
        }


encodeUploadResource : SHA256.Digest -> String -> Json.Encode.Value
encodeUploadResource hash content =
    Json.Encode.object
        [ ( "data"
          , Json.Encode.object
                [ ( "type", Json.Encode.string "resources" )
                , ( "id", SHA256.toHex hash |> Json.Encode.string )
                , ( "attributes"
                  , Json.Encode.object
                        [ ( "base64-content"
                          , Json.Encode.string content
                          )
                        ]
                  )
                ]
          )
        ]


createSnapshot :
    PercyApiKey
    -> BuildId
    ->
        { name : String
        , widths : Nonempty Int
        , minHeight : Maybe Int
        , resources : Nonempty SnapshotResource
        }
    -> Task Error ()
createSnapshot (PercyApiKey apiKey) (BuildId buildId) data =
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Token " ++ apiKey) ]
        , url = Url.Builder.crossOrigin percyApiDomain [ "builds", buildId, "snapshots" ] []
        , body = Http.jsonBody (encodeCreateSnapshot data)
        , resolver = Http.stringResolver (resolver (Json.Decode.succeed ()))
        , timeout = Nothing
        }


encodeCreateSnapshot :
    { name : String
    , widths : Nonempty Int
    , minHeight : Maybe Int
    , resources : Nonempty SnapshotResource
    }
    -> Json.Encode.Value
encodeCreateSnapshot data =
    Json.Encode.object
        [ ( "data"
          , Json.Encode.object
                [ ( "type", Json.Encode.string "snapshots" )
                , ( "attributes"
                  , Json.Encode.object
                        [ ( "name", Json.Encode.string data.name )
                        , ( "widths"
                          , List.Nonempty.toList data.widths
                                |> List.map (clamp 10 2000)
                                |> Json.Encode.list Json.Encode.int
                          )
                        , ( "minimum-height"
                          , case data.minHeight of
                                Just minHeight ->
                                    Json.Encode.int (clamp 10 2000 minHeight)

                                Nothing ->
                                    Json.Encode.null
                          )
                        ]
                  )
                , ( "relationships"
                  , Json.Encode.object
                        [ ( "resources"
                          , Json.Encode.object
                                [ ( "data"
                                  , Json.Encode.list encodeResource (List.Nonempty.toList data.resources)
                                  )
                                ]
                          )
                        ]
                  )
                ]
          )
        ]


{-| An API key needed to upload snapshots to Percy.io. Create an account first in order to get an API key.
-}
type PercyApiKey
    = PercyApiKey String


type alias BuildData =
    { attributes :
        { branch : String
        , targetBranch : String
        }
    , relationships :
        { resources :
            { data : List SnapshotResource }
        }
    }


type BuildId
    = BuildId String


type alias BuildResponse =
    { data : { buildId : BuildId }
    }


buildResponseDecoder : Decoder BuildResponse
buildResponseDecoder =
    Json.Decode.map BuildResponse
        (Json.Decode.field
            "data"
            (Json.Decode.map (\id -> { buildId = id })
                (Json.Decode.field "id" buildIdDecoder)
            )
        )


buildIdDecoder : Decoder BuildId
buildIdDecoder =
    Json.Decode.string |> Json.Decode.map BuildId


encodeBuildData : BuildData -> Json.Encode.Value
encodeBuildData buildData =
    Json.Encode.object
        [ ( "data"
          , Json.Encode.object
                [ ( "type", Json.Encode.string "builds" )
                , ( "attributes"
                  , Json.Encode.object
                        [ ( "branch", Json.Encode.string buildData.attributes.branch )
                        , ( "target-branch", Json.Encode.string buildData.attributes.targetBranch )
                        ]
                  )
                , ( "relationships"
                  , Json.Encode.object
                        [ ( "resources"
                          , Json.Encode.object
                                [ ( "data"
                                  , Json.Encode.list encodeResource buildData.relationships.resources.data
                                  )
                                ]
                          )
                        ]
                  )
                ]
          )
        ]


encodeResource : SnapshotResource -> Json.Encode.Value
encodeResource resource =
    Json.Encode.object
        [ ( "type", Json.Encode.string "resources" )
        , ( "id", SHA256.toHex resource.id |> Json.Encode.string )
        , ( "attributes"
          , Json.Encode.object
                [ ( "resource-url", Json.Encode.string resource.attributes.resourceUrl )
                , ( "is-root", Json.Encode.bool resource.attributes.isRoot )
                , ( "mimetype", encodeMaybe Json.Encode.string resource.attributes.mimeType )
                ]
          )
        ]


encodeMaybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
encodeMaybe encoder maybe =
    case maybe of
        Just value ->
            encoder value

        Nothing ->
            Json.Encode.null


createBuild : PercyApiKey -> BuildData -> Task Error BuildResponse
createBuild (PercyApiKey apiKey) buildData =
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Token " ++ apiKey) ]
        , url = Url.Builder.crossOrigin percyApiDomain [ "builds" ] []
        , body = Http.jsonBody (encodeBuildData buildData)
        , resolver = Http.stringResolver (resolver buildResponseDecoder)
        , timeout = Nothing
        }


{-| Possible errors when uploading snapshots.
-}
type Error
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus { statusCode : Int, body : String }
    | BadBody String
    | SnapshotNamesNotUnique


{-| Convert the error into a human readable form.
-}
errorToString : Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "Bad url: " ++ url

        Timeout ->
            "Request timed out"

        NetworkError ->
            "Network error"

        BadStatus { statusCode, body } ->
            String.fromInt statusCode ++ " error: " ++ body

        BadBody jsonError ->
            "Bad body: " ++ jsonError

        SnapshotNamesNotUnique ->
            "Snapshot names must be unique"


resolver : Decoder a -> Http.Response String -> Result Error a
resolver decoder =
    \response ->
        case response of
            Http.BadUrl_ url ->
                BadUrl url |> Err

            Http.Timeout_ ->
                Err Timeout

            Http.NetworkError_ ->
                Err NetworkError

            Http.BadStatus_ metadata body ->
                BadStatus { statusCode = metadata.statusCode, body = body } |> Err

            Http.GoodStatus_ _ body ->
                case Json.Decode.decodeString decoder body of
                    Ok ok ->
                        Ok ok

                    Err error ->
                        Json.Decode.errorToString error |> BadBody |> Err


finalize : PercyApiKey -> BuildId -> Task Error Response
finalize (PercyApiKey apiKey) (BuildId buildId) =
    Http.task
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Token " ++ apiKey) ]
        , url = Url.Builder.crossOrigin percyApiDomain [ "builds", buildId, "finalize" ] []
        , body = Http.emptyBody
        , resolver = Http.stringResolver (resolver finalizeResponseDecoder)
        , timeout = Nothing
        }


{-| Response from server after we upload snapshots.
-}
type alias Response =
    { success : Bool }


finalizeResponseDecoder : Decoder Response
finalizeResponseDecoder =
    Json.Decode.map Response
        (Json.Decode.field "success" Json.Decode.bool)
