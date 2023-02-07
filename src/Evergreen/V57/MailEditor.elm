module Evergreen.V57.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V57.Color
import Evergreen.V57.Coord
import Evergreen.V57.DisplayName
import Evergreen.V57.Id
import Evergreen.V57.Shaders
import Evergreen.V57.Tile
import Pixels


type Image
    = Stamp Evergreen.V57.Color.Colors
    | SunglassesEmoji Evergreen.V57.Color.Colors
    | NormalEmoji Evergreen.V57.Color.Colors
    | SadEmoji Evergreen.V57.Color.Colors
    | Cow Evergreen.V57.Color.Colors
    | Man Evergreen.V57.Color.Colors
    | TileImage Evergreen.V57.Tile.TileGroup Int Evergreen.V57.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V57.Color.Colors
    | DragCursor Evergreen.V57.Color.Colors
    | PinchCursor Evergreen.V57.Color.Colors
    | Line Int Evergreen.V57.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V57.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , to : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V57.Id.Id Evergreen.V57.Id.MailId)
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
    | TextTool (Evergreen.V57.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V57.Id.Id Evergreen.V57.Id.UserId, Evergreen.V57.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V57.Id.Id Evergreen.V57.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , to : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    }
