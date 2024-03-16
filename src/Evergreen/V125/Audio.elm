module Evergreen.V125.Audio exposing (..)

import Dict
import Duration
import Effect.Time
import List.Nonempty


type LoadError
    = FailedToDecode
    | NetworkError
    | UnknownError
    | ErrorThatHappensWhenYouLoadMoreThan1000SoundsDueToHackyWorkAroundToMakeThisPackageBehaveMoreLikeAnEffectPackage


type BufferId
    = BufferId Int


type Source
    = File
        { bufferId : BufferId
        }


type alias NodeGroupId =
    Int


type alias LoopConfig =
    { loopStart : Duration.Duration
    , loopEnd : Duration.Duration
    }


type alias FlattenedAudio =
    { source : Source
    , startTime : Effect.Time.Posix
    , startAt : Duration.Duration
    , offset : Duration.Duration
    , volume : Float
    , volumeTimelines : List (List.Nonempty.Nonempty ( Effect.Time.Posix, Float ))
    , loop : Maybe LoopConfig
    , playbackRate : Float
    }


type alias AudioLoadRequest_ userMsg =
    { userMsg : List.Nonempty.Nonempty ( Result LoadError Source, userMsg )
    , audioUrl : String
    }


type alias SourceData =
    { duration : Duration.Duration
    }


type alias Model_ userMsg userModel =
    { audioState : Dict.Dict NodeGroupId FlattenedAudio
    , nodeGroupIdCounter : Int
    , userModel : userModel
    , requestCount : Int
    , pendingRequests : Dict.Dict Int (AudioLoadRequest_ userMsg)
    , samplesPerSecond : Maybe Int
    , sourceData : Dict.Dict Int SourceData
    }


type Model userMsg userModel
    = Model (Model_ userMsg userModel)


type FromJSMsg
    = AudioLoadSuccess
        { requestId : Int
        , bufferId : BufferId
        , duration : Duration.Duration
        }
    | AudioLoadFailed
        { requestId : Int
        , error : LoadError
        }
    | InitAudioContext
        { samplesPerSecond : Int
        }
    | JsonParseError
        { error : String
        }


type Msg userMsg
    = FromJSMsg FromJSMsg
    | UserMsg userMsg
