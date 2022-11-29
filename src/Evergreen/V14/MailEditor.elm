module Evergreen.V14.MailEditor exposing (..)

import Evergreen.V14.Coord
import Evergreen.V14.Id
import Evergreen.V14.Point2d
import Evergreen.V14.Shaders
import Evergreen.V14.Units
import Pixels
import Time
import WebGL


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , to : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.MailPixelUnit
            , image : Image
            }
    , currentImage : Image
    }


type alias EditorState =
    { content :
        List
            { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Time.Posix
        , startPosition : Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Time.Posix
        , startPosition : Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : WebGL.Mesh Evergreen.V14.Shaders.Vertex
    , textInputMesh : WebGL.Mesh Evergreen.V14.Shaders.Vertex
    , currentImage : Image
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , showMailEditor : ShowMailEditor
    , lastPlacedImage : Maybe Time.Posix
    , submitStatus : SubmitStatus
    , textInputFocused : Bool
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , to : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
