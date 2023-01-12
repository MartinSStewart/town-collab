module Evergreen.V33.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V33.Coord
import Evergreen.V33.Id
import Evergreen.V33.Point2d
import Evergreen.V33.Shaders
import Evergreen.V33.Units
import Pixels


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData =
    { to : String
    , content :
        List
            { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.MailPixelUnit
            , image : Image
            }
    , currentImage : Image
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V33.Id.Id Evergreen.V33.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , to : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    }


type Hover
    = BackgroundHover
    | MailHover
    | UserIdInputHover
    | SubmitButtonHover


type alias EditorState =
    { content :
        List
            { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.MailPixelUnit
            , image : Image
            }
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening
        { startTime : Effect.Time.Posix
        , startPosition : Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MailEditorClosing
        { startTime : Effect.Time.Posix
        , startPosition : Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model =
    { mesh : Effect.WebGL.Mesh Evergreen.V33.Shaders.Vertex
    , textInputMesh : Effect.WebGL.Mesh Evergreen.V33.Shaders.Vertex
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
            { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.MailPixelUnit
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , to : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    }


type ToBackend
    = SubmitMailRequest
        { content :
            List
                { position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.MailPixelUnit
                , image : Image
                }
        , to : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse
