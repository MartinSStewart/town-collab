module Sound exposing (Sound(..), load, play)

import AssocList as Dict exposing (Dict)
import Audio exposing (Audio, AudioCmd)
import Time


type Sound
    = PopSound
    | CrackleSound
    | TrainWhistleSound


allSounds =
    [ PopSound
    , CrackleSound
    , TrainWhistleSound
    ]


play : Dict Sound (Result Audio.LoadError Audio.Source) -> Sound -> Time.Posix -> Audio
play dict sound startTime =
    case Dict.get sound dict of
        Just (Ok audio) ->
            Audio.audio audio startTime

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
            )
                |> Audio.loadAudio (onLoad sound)
        )
        allSounds
        |> Audio.cmdBatch
