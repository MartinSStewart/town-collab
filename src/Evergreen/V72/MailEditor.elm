module Evergreen.V72.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V72.Color
import Evergreen.V72.Coord
import Evergreen.V72.DisplayName
import Evergreen.V72.Id
import Evergreen.V72.Shaders
import Evergreen.V72.Tile
import Pixels


type Image
    = Stamp Evergreen.V72.Color.Colors
    | SunglassesEmoji Evergreen.V72.Color.Colors
    | NormalEmoji Evergreen.V72.Color.Colors
    | SadEmoji Evergreen.V72.Color.Colors
    | Cow Evergreen.V72.Color.Colors
    | Man Evergreen.V72.Color.Colors
    | TileImage Evergreen.V72.Tile.TileGroup Int Evergreen.V72.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V72.Color.Colors
    | DragCursor Evergreen.V72.Color.Colors
    | PinchCursor Evergreen.V72.Color.Colors
    | Line Int Evergreen.V72.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V72.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , to : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V72.Id.Id Evergreen.V72.Id.MailId)
    | TextToolButton


type alias ImagePlacer_ =
    { imageIndex : Int
    , rotationIndex : Int
    }


type TextUnit
    = TextUnit Never


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool
    | TextTool (Evergreen.V72.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V72.Id.Id Evergreen.V72.Id.UserId, Evergreen.V72.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V72.Id.Id Evergreen.V72.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , to : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    }
