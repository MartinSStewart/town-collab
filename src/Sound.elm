module Sound exposing (Sound(..), length, load, play, playWithConfig)

import AssocList as Dict exposing (Dict)
import Audio exposing (Audio, AudioCmd, AudioData, PlayAudioConfig)
import Duration exposing (Duration)
import Quantity
import Time


type Sound
    = PopSound
    | CrackleSound
    | TrainWhistleSound
    | ChugaChuga
    | EraseSound
    | PageTurnSound
    | WhooshSound
    | ErrorSound
    | KnockKnockSound
    | OldManSound
    | MmhmmSound
    | NuhHuhSound
    | HelloSound
    | Hello2Sound


allSounds =
    [ PopSound
    , CrackleSound
    , TrainWhistleSound
    , ChugaChuga
    , EraseSound
    , PageTurnSound
    , WhooshSound
    , ErrorSound
    , KnockKnockSound
    , OldManSound
    , MmhmmSound
    , NuhHuhSound
    , HelloSound
    , Hello2Sound
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
            ("/"
                ++ (case sound of
                        PopSound ->
                            "pop.mp3"

                        CrackleSound ->
                            "crackle.mp3"

                        TrainWhistleSound ->
                            "train-whistle.mp3"

                        ChugaChuga ->
                            "chuga-chuga.mp3"

                        EraseSound ->
                            "erase.mp3"

                        PageTurnSound ->
                            "page-turn.mp3"

                        WhooshSound ->
                            "whoosh.mp3"

                        ErrorSound ->
                            "error.mp3"

                        KnockKnockSound ->
                            "knock-knock.mp3"

                        OldManSound ->
                            "old-man.mp3"

                        MmhmmSound ->
                            "mmhmm.mp3"

                        NuhHuhSound ->
                            "nuh-huh.mp3"

                        HelloSound ->
                            "hello.mp3"

                        Hello2Sound ->
                            "hello2.mp3"
                   )
            )
                |> Audio.loadAudio (onLoad sound)
        )
        allSounds
        |> Audio.cmdBatch


length : AudioData -> Dict Sound (Result Audio.LoadError Audio.Source) -> Sound -> Duration
length audioData dict sound =
    case Dict.get sound dict of
        Just (Ok audio) ->
            Audio.length audioData audio

        _ ->
            Quantity.zero
