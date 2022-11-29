module Evergreen.V12.PingData exposing (..)

import Duration
import Time


type alias PingData =
    { roundTripTime : Duration.Duration
    , serverTime : Time.Posix
    , sendTime : Time.Posix
    , receiveTime : Time.Posix
    , lowEstimate : Duration.Duration
    , highEstimate : Duration.Duration
    , pingCount : Int
    }
