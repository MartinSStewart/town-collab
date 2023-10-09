module TimeOfDay exposing (TimeOfDay(..), isDayTime, nightFactor, sunMoonPosition)

import Coord exposing (Coord)
import Effect.Time as Time
import Pixels exposing (Pixels)


type TimeOfDay
    = Automatic
    | AlwaysDay
    | AlwaysNight


nightFactor : TimeOfDay -> Time.Posix -> Float
nightFactor timeOfDay time =
    case timeOfDay of
        Automatic ->
            let
                hour =
                    toFloat (Time.toHour Time.utc time)
                        + (toFloat (Time.toMinute Time.utc time) / 60)
                        + (toFloat (Time.toSecond Time.utc time) / (60 * 60))
            in
            if hour < 5 then
                1

            else if hour < 8 then
                (8 - hour) / 3

            else if hour < 18 then
                0

            else if hour < 21 then
                (hour - 18) / 3

            else
                1

        AlwaysDay ->
            0

        AlwaysNight ->
            1


isDayTime : Float -> Bool
isDayTime factor =
    factor <= 0.5


sunMoonPosition : { a | windowSize : Coord Pixels, zoomFactor : Int } -> Float -> Coord Pixels
sunMoonPosition { windowSize, zoomFactor } factor =
    let
        yOffset =
            if isDayTime factor then
                0.4 - 0.9 * (factor * 2)

            else
                -0.5 + 0.9 * ((factor - 0.5) * 2)
    in
    Coord.xy
        ((toFloat (Coord.xRaw windowSize) * -0.3 / toFloat zoomFactor) |> round |> negate)
        ((toFloat (Coord.yRaw windowSize) * yOffset / toFloat zoomFactor) |> round |> negate)
