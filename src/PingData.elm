module PingData exposing (ClientTime(..), PingData)

import Duration exposing (Duration)
import Time


type ClientTime
    = ClientTime Time.Posix


type alias PingData =
    { roundTripTime : Duration
    , serverTime : Time.Posix
    , sendTime : Time.Posix
    , receiveTime : Time.Posix
    , lowEstimate : Duration
    , highEstimate : Duration
    , pingCount : Int
    }
