module Mail exposing (BackendMail, FrontendMail, MailStatus(..))

import Id exposing (Id, TrainId, UserId)


type alias BackendMail =
    { message : String
    , status : MailStatus
    , sender : Id UserId
    , recipient : Id UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , sender : Id UserId
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Id TrainId)
    | MailReceived
