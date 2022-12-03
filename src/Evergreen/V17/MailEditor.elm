module Evergreen.V17.MailEditor exposing (..)

import Evergreen.V17.Coord
import Evergreen.V17.Id
import Evergreen.V17.Point2d
import Evergreen.V17.Shaders
import Evergreen.V17.Units
import Pixels
import Time
import WebGL


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias FrontendMail = 
    { status : MailStatus
    , from : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , to : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


type alias MailEditorData = 
    { to : String
    , content : (List 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.MailPixelUnit)
    , image : Image
    })
    , currentImage : Image
    }


type Hover
    = BackgroundHover
    | MailHover
    | UserIdInputHover
    | SubmitButtonHover


type alias EditorState = 
    { content : (List 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.MailPixelUnit)
    , image : Image
    })
    , to : String
    }


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening 
    { startTime : Time.Posix
    , startPosition : (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    }
    | MailEditorClosing 
    { startTime : Time.Posix
    , startPosition : (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias Model = 
    { mesh : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    , textInputMesh : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    , currentImage : Image
    , undo : (List EditorState)
    , current : EditorState
    , redo : (List EditorState)
    , showMailEditor : ShowMailEditor
    , lastPlacedImage : (Maybe Time.Posix)
    , submitStatus : SubmitStatus
    , textInputFocused : Bool
    }


type alias BackendMail = 
    { content : (List 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.MailPixelUnit)
    , image : Image
    })
    , status : MailStatus
    , from : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , to : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    }


type ToBackend
    = SubmitMailRequest 
    { content : (List 
    { position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.MailPixelUnit)
    , image : Image
    })
    , to : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse