module Evergreen.V47.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V47.Color
import Evergreen.V47.Coord
import Evergreen.V47.DisplayName
import Evergreen.V47.Id
import Evergreen.V47.Shaders
import Evergreen.V47.Tile
import Pixels


type Image
    = Stamp Evergreen.V47.Color.Colors
    | SunglassesEmoji Evergreen.V47.Color.Colors
    | NormalEmoji Evergreen.V47.Color.Colors
    | SadEmoji Evergreen.V47.Color.Colors
    | Cow Evergreen.V47.Color.Colors
    | Man Evergreen.V47.Color.Colors
    | TileImage Evergreen.V47.Tile.TileGroup Int Evergreen.V47.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V47.Color.Colors
    | DragCursor Evergreen.V47.Color.Colors
    | PinchCursor Evergreen.V47.Color.Colors


type alias Content =
    { position : Evergreen.V47.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V47.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , to : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V47.Id.Id Evergreen.V47.Id.MailId)


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
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V47.Id.Id Evergreen.V47.Id.UserId, Evergreen.V47.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V47.Id.Id Evergreen.V47.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V47.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , to : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    }
