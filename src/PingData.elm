module PingData exposing (PingData, pingOffset)

import Duration exposing (Duration)
import Effect.Time
import Quantity


type alias PingData =
    { roundTripTime : Duration
    , serverTime : Effect.Time.Posix
    , sendTime : Effect.Time.Posix
    , receiveTime : Effect.Time.Posix
    , lowEstimate : Duration
    , highEstimate : Duration
    , pingCount : Int
    }


pingOffset : { a | pingData : Maybe PingData } -> Duration
pingOffset model =
    case model.pingData of
        Just pingData ->
            Quantity.plus pingData.lowEstimate pingData.highEstimate
                |> Quantity.divideBy 2
                |> Quantity.negate

        Nothing ->
            Quantity.zero
