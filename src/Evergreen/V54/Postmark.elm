module Evergreen.V54.Postmark exposing (..)


type alias PostmarkSendResponse =
    { to : String
    , submittedAt : String
    , messageId : String
    , errorCode : Int
    , message : String
    }
