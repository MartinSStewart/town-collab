module Sound exposing (Sound(..), load, play, playWithConfig)

import AssocList as Dict exposing (Dict)
import Audio exposing (Audio, AudioCmd, AudioData, PlayAudioConfig)
import Duration exposing (Duration)
import Time


type Sound
    = PopSound
    | CrackleSound
    | TrainWhistleSound
    | ChugaChuga


allSounds =
    [ PopSound
    , CrackleSound
    , TrainWhistleSound
    , ChugaChuga
    ]


play : Dict Sound (Result Audio.LoadError Audio.Source) -> Sound -> Time.Posix -> Audio
play dict sound startTime =
    case Dict.get sound dict of
        Just (Ok audio) ->
            Audio.audio audio startTime

        _ ->
            Audio.silence


playWithConfig :
    AudioData
    -> Dict Sound (Result Audio.LoadError Audio.Source)
    -> (Duration -> PlayAudioConfig)
    -> Sound
    -> Time.Posix
    -> Audio
playWithConfig audioData dict config sound startTime =
    case Dict.get sound dict of
        Just (Ok audio) ->
            Audio.audioWithConfig (config (Audio.length audioData audio)) audio startTime

        _ ->
            Audio.silence


load : (Sound -> Result Audio.LoadError Audio.Source -> msg) -> AudioCmd msg
load onLoad =
    List.map
        (\sound ->
            (case sound of
                PopSound ->
                    "/pop.mp3"

                CrackleSound ->
                    "/crackle.mp3"

                TrainWhistleSound ->
                    "/train-whistle.mp3"

                ChugaChuga ->
                    "/chuga-chuga.mp3"
            )
                |> Audio.loadAudio (onLoad sound)
        )
        allSounds
        |> Audio.cmdBatch