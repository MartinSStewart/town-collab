module Evergreen.V29.MailEditor exposing (..)

import Evergreen.V29.Coord
import Evergreen.V29.Id
import Evergreen.V29.Point2d
import Evergreen.V29.Shaders
import Evergreen.V29.Units
import Pixels
import Time
import WebGL


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , to : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.MailPixelUnit
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
            { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Time.Posix
        , startPosition : Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Time.Posix
        , startPosition : Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : WebGL.Mesh Evergreen.V29.Shaders.Vertex
    , textInputMesh : WebGL.Mesh Evergreen.V29.Shaders.Vertex
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
            { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , to : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
