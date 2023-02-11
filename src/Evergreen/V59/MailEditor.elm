module Evergreen.V59.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V59.Color
import Evergreen.V59.Coord
import Evergreen.V59.DisplayName
import Evergreen.V59.Id
import Evergreen.V59.Shaders
import Evergreen.V59.Tile
import Pixels


type Image
    = Stamp Evergreen.V59.Color.Colors
    | SunglassesEmoji Evergreen.V59.Color.Colors
    | NormalEmoji Evergreen.V59.Color.Colors
    | SadEmoji Evergreen.V59.Color.Colors
    | Cow Evergreen.V59.Color.Colors
    | Man Evergreen.V59.Color.Colors
    | TileImage Evergreen.V59.Tile.TileGroup Int Evergreen.V59.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V59.Color.Colors
    | DragCursor Evergreen.V59.Color.Colors
    | PinchCursor Evergreen.V59.Color.Colors
    | Line Int Evergreen.V59.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V59.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , to : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V59.Id.Id Evergreen.V59.Id.MailId)
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
    | TextTool (Evergreen.V59.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V59.Id.Id Evergreen.V59.Id.UserId, Evergreen.V59.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V59.Id.Id Evergreen.V59.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , to : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    }
