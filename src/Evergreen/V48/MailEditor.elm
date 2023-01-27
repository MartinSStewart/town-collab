module Evergreen.V48.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V48.Color
import Evergreen.V48.Coord
import Evergreen.V48.DisplayName
import Evergreen.V48.Id
import Evergreen.V48.Shaders
import Evergreen.V48.Tile
import Pixels


type Image
    = Stamp Evergreen.V48.Color.Colors
    | SunglassesEmoji Evergreen.V48.Color.Colors
    | NormalEmoji Evergreen.V48.Color.Colors
    | SadEmoji Evergreen.V48.Color.Colors
    | Cow Evergreen.V48.Color.Colors
    | Man Evergreen.V48.Color.Colors
    | TileImage Evergreen.V48.Tile.TileGroup Int Evergreen.V48.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V48.Color.Colors
    | DragCursor Evergreen.V48.Color.Colors
    | PinchCursor Evergreen.V48.Color.Colors


type alias Content =
    { position : Evergreen.V48.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V48.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , to : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V48.Id.Id Evergreen.V48.Id.MailId)


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
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V48.Id.Id Evergreen.V48.Id.UserId, Evergreen.V48.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V48.Id.Id Evergreen.V48.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V48.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , to : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    }
