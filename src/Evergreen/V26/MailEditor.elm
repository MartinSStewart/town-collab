module Evergreen.V26.MailEditor exposing (..)

import Evergreen.V26.Coord
import Evergreen.V26.Id
import Evergreen.V26.Point2d
import Evergreen.V26.Shaders
import Evergreen.V26.Units
import Pixels
import Time
import WebGL


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , to : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.MailPixelUnit
            , image : Image
            }
    , currentImage : Image
    }


type Hover
    = BackgroundHover
    | MailHover
    | UserIdInputHover
    | SubmitButtonHover


type alias EditorState =
    { content :
        List
            { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Time.Posix
        , startPosition : Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Time.Posix
        , startPosition : Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : WebGL.Mesh Evergreen.V26.Shaders.Vertex
    , textInputMesh : WebGL.Mesh Evergreen.V26.Shaders.Vertex
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
            { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , to : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
