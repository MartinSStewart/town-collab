module Evergreen.V44.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V44.Coord
import Evergreen.V44.Id
import Evergreen.V44.Point2d
import Evergreen.V44.Shaders
import Evergreen.V44.Units
import Pixels


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.MailPixelUnit
            , image : Image
            }
    , currentImage : Image
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V44.Id.Id Evergreen.V44.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    , to : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    }


type Hover
    = BackgroundHover
    | MailHover
    | UserIdInputHover
    | SubmitButtonHover


type alias EditorState =
    { content :
        List
            { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Effect.Time.Posix
        , startPosition : Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Effect.Time.Posix
        , startPosition : Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : Effect.WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , textInputMesh : Effect.WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , currentImage : Image
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , showMailEditor : ShowMailEditor
    , lastPlacedImage : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , textInputFocused : Bool
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    , to : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
