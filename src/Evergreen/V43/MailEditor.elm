module Evergreen.V43.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V43.Coord
import Evergreen.V43.Id
import Evergreen.V43.Point2d
import Evergreen.V43.Shaders
import Evergreen.V43.Units
import Pixels


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.MailPixelUnit
            , image : Image
            }
    , currentImage : Image
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V43.Id.Id Evergreen.V43.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    , to : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    }


type Hover
    = BackgroundHover
    | MailHover
    | UserIdInputHover
    | SubmitButtonHover


type alias EditorState =
    { content :
        List
            { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Effect.Time.Posix
        , startPosition : Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Effect.Time.Posix
        , startPosition : Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : Effect.WebGL.Mesh Evergreen.V43.Shaders.Vertex
    , textInputMesh : Effect.WebGL.Mesh Evergreen.V43.Shaders.Vertex
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
            { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    , to : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
