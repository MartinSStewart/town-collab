module Evergreen.V52.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V52.Color
import Evergreen.V52.Coord
import Evergreen.V52.DisplayName
import Evergreen.V52.Id
import Evergreen.V52.Shaders
import Evergreen.V52.Tile
import Pixels


type Image
    = Stamp Evergreen.V52.Color.Colors
    | SunglassesEmoji Evergreen.V52.Color.Colors
    | NormalEmoji Evergreen.V52.Color.Colors
    | SadEmoji Evergreen.V52.Color.Colors
    | Cow Evergreen.V52.Color.Colors
    | Man Evergreen.V52.Color.Colors
    | TileImage Evergreen.V52.Tile.TileGroup Int Evergreen.V52.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V52.Color.Colors
    | DragCursor Evergreen.V52.Color.Colors
    | PinchCursor Evergreen.V52.Color.Colors
    | Line Int Evergreen.V52.Color.Color


type alias Content =
    { position : Evergreen.V52.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V52.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , to : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V52.Id.Id Evergreen.V52.Id.MailId)


type alias ImagePlacer_ =
    { imageIndex : Int
    , rotationIndex : Int
    }


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V52.Id.Id Evergreen.V52.Id.UserId, Evergreen.V52.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V52.Id.Id Evergreen.V52.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V52.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , to : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    }
