module Sound exposing (Model, Sound(..), length, load, maxVolume, nextSong, play, playWithConfig)

import AssocList as Dict exposing (Dict)
import Audio exposing (Audio, AudioCmd, AudioData, PlayAudioConfig)
import Duration exposing (Duration)
import Effect.Time
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Quantity
import Random


type alias Model a =
    { a
        | sounds : Dict Sound (Result Audio.LoadError Audio.Source)
        , musicVolume : Int
        , soundEffectVolume : Int
    }


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
    | Music2
    | Ambience0
    | Moo0
    | Moo1
    | Moo2
    | Moo3
    | Moo4
    | Moo5
    | Moo6
    | RailToggleSound
    | Meow
    | TrainCrash
    | Sheep0
    | Sheep1
    | Hamster0
    | Hamster1
    | Hamster2
    | LightSwitch


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
    , Music2
    , Ambience0
    , Moo0
    , Moo1
    , Moo2
    , Moo3
    , Moo4
    , Moo5
    , Moo6
    , RailToggleSound
    , Meow
    , TrainCrash
    , Sheep0
    , Sheep1
    , Hamster0
    , Hamster1
    , Hamster2
    , LightSwitch
    ]


songs =
    Nonempty Music0 [ Music1, Music2 ]


isMusic : Sound -> Bool
isMusic sound =
    List.Nonempty.any ((==) sound) songs


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


maxVolume : number
maxVolume =
    10


play : Model a -> Sound -> Effect.Time.Posix -> Audio
play model sound startTime =
    case Dict.get sound model.sounds of
        Just (Ok audio) ->
            Audio.audio audio startTime
                |> (if isMusic sound then
                        Audio.scaleVolume (toFloat model.musicVolume / maxVolume)

                    else
                        Audio.scaleVolume (toFloat model.soundEffectVolume / maxVolume)
                   )

        _ ->
            Audio.silence


playWithConfig : AudioData -> Model a -> (Duration -> PlayAudioConfig) -> Sound -> Effect.Time.Posix -> Audio
playWithConfig audioData model config sound startTime =
    case Dict.get sound model.sounds of
        Just (Ok audio) ->
            Audio.audioWithConfig (config (Audio.length audioData audio)) audio startTime
                |> (if isMusic sound then
                        Audio.scaleVolume (toFloat model.musicVolume / maxVolume)

                    else
                        Audio.scaleVolume (toFloat model.soundEffectVolume / maxVolume)
                   )

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

                        Music2 ->
                            "now-arriving-at.mp3"

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

                        RailToggleSound ->
                            "rail-toggle.mp3"

                        Meow ->
                            "meow.mp3"

                        TrainCrash ->
                            "train-crash.mp3"

                        Sheep0 ->
                            "sheep0.mp3"

                        Sheep1 ->
                            "sheep1.mp3"

                        Hamster0 ->
                            "hamster0.mp3"

                        Hamster1 ->
                            "hamster1.mp3"

                        Hamster2 ->
                            "hamster2.mp3"

                        LightSwitch ->
                            "light-switch.mp3"
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
