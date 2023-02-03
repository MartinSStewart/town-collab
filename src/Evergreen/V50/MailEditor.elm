module Evergreen.V50.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V50.Color
import Evergreen.V50.Coord
import Evergreen.V50.DisplayName
import Evergreen.V50.Id
import Evergreen.V50.Shaders
import Evergreen.V50.Tile
import Pixels


type Image
    = Stamp Evergreen.V50.Color.Colors
    | SunglassesEmoji Evergreen.V50.Color.Colors
    | NormalEmoji Evergreen.V50.Color.Colors
    | SadEmoji Evergreen.V50.Color.Colors
    | Cow Evergreen.V50.Color.Colors
    | Man Evergreen.V50.Color.Colors
    | TileImage Evergreen.V50.Tile.TileGroup Int Evergreen.V50.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V50.Color.Colors
    | DragCursor Evergreen.V50.Color.Colors
    | PinchCursor Evergreen.V50.Color.Colors
    | Line Int Evergreen.V50.Color.Color


type alias Content =
    { position : Evergreen.V50.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V50.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , to : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V50.Id.Id Evergreen.V50.Id.MailId)


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
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V50.Id.Id Evergreen.V50.Id.UserId, Evergreen.V50.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V50.Id.Id Evergreen.V50.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V50.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , to : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    }
