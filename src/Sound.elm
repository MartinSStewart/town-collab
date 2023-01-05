module Sound exposing (Sound(..), length, load, nextSong, play, playWithConfig)

import AssocList as Dict exposing (Dict)
import Audio exposing (Audio, AudioCmd, AudioData, PlayAudioConfig)
import Duration exposing (Duration)
import Effect.Time
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Quantity
import Random


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
    | TeleportSound
    | Music0
    | Music1
    | Ambience0
    | Moo0
    | Moo1
    | Moo2
    | Moo3
    | Moo4
    | Moo5
    | Moo6


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
    , TeleportSound
    , Music0
    , Music1
    , Ambience0
    , Moo0
    , Moo1
    , Moo2
    , Moo3
    , Moo4
    , Moo5
    , Moo6
    ]


songs =
    Nonempty Music0 [ Music1 ]


nextSong : Maybe Sound -> Random.Generator Sound
nextSong maybePreviousSong =
    case maybePreviousSong of
        Just previousSong ->
            case List.Nonempty.toList songs |> List.remove previousSong |> List.Nonempty.fromList of
                Just nonempty ->
                    List.Nonempty.sample nonempty

                Nothing ->
                    List.Nonempty.sample songs

        Nothing ->
            List.Nonempty.sample songs


play : Dict Sound (Result Audio.LoadError Audio.Source) -> Sound -> Effect.Time.Posix -> Audio
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
    -> Effect.Time.Posix
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

                        TeleportSound ->
                            "teleport.mp3"

                        Music0 ->
                            "grasslands.mp3"

                        Music1 ->
                            "dawn.mp3"

                        Ambience0 ->
                            "windy-grasslands-ambience.mp3"

                        Moo0 ->
                            "moo0.mp3"

                        Moo1 ->
                            "moo1.mp3"

                        Moo2 ->
                            "moo2.mp3"

                        Moo3 ->
                            "moo3.mp3"

                        Moo4 ->
                            "moo4.mp3"

                        Moo5 ->
                            "moo5.mp3"

                        Moo6 ->
                            "moo6.mp3"
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
