module Evergreen.V56.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V56.Color
import Evergreen.V56.Coord
import Evergreen.V56.DisplayName
import Evergreen.V56.Id
import Evergreen.V56.Shaders
import Evergreen.V56.Tile
import Pixels


type Image
    = Stamp Evergreen.V56.Color.Colors
    | SunglassesEmoji Evergreen.V56.Color.Colors
    | NormalEmoji Evergreen.V56.Color.Colors
    | SadEmoji Evergreen.V56.Color.Colors
    | Cow Evergreen.V56.Color.Colors
    | Man Evergreen.V56.Color.Colors
    | TileImage Evergreen.V56.Tile.TileGroup Int Evergreen.V56.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V56.Color.Colors
    | DragCursor Evergreen.V56.Color.Colors
    | PinchCursor Evergreen.V56.Color.Colors
    | Line Int Evergreen.V56.Color.Color


type alias Content =
    { position : Evergreen.V56.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V56.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , to : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V56.Id.Id Evergreen.V56.Id.MailId)


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
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V56.Id.Id Evergreen.V56.Id.UserId, Evergreen.V56.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V56.Id.Id Evergreen.V56.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V56.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , to : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    }
