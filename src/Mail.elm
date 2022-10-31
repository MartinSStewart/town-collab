module Mail exposing
    ( BackendMail
    , FrontendMail
    , MailEditor
    , MailStatus(..)
    , getImageData
    , initEditor
    )

import Coord exposing (Coord)
import Id exposing (Id, TrainId, UserId)
import Pixels exposing (Pixels)


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


type alias MailEditor =
    { recipient : Maybe (Id UserId)
    , content : List { position : Coord Pixels, image : Image }
    }


type Image
    = BlueStamp


initEditor : MailEditor
initEditor =
    { recipient = Nothing
    , content = []
    }


getImageData : Image -> { textureSize : ( Int, Int ), texturePosition : ( Int, Int ) }
getImageData image =
    case image of
        BlueStamp ->
            { textureSize = ( 28, 28 ), texturePosition = ( 504, 0 ) }
