module Evergreen.V18.MailEditor exposing (..)

import Evergreen.V18.Coord
import Evergreen.V18.Id
import Evergreen.V18.Point2d
import Evergreen.V18.Shaders
import Evergreen.V18.Units
import Pixels
import Time
import WebGL


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    , to : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.MailPixelUnit
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
            { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Time.Posix
        , startPosition : Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Time.Posix
        , startPosition : Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : WebGL.Mesh Evergreen.V18.Shaders.Vertex
    , textInputMesh : WebGL.Mesh Evergreen.V18.Shaders.Vertex
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
            { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    , to : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
