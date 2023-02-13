module Evergreen.V67.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V67.Color
import Evergreen.V67.Coord
import Evergreen.V67.DisplayName
import Evergreen.V67.Id
import Evergreen.V67.Shaders
import Evergreen.V67.Tile
import Pixels


type Image
    = Stamp Evergreen.V67.Color.Colors
    | SunglassesEmoji Evergreen.V67.Color.Colors
    | NormalEmoji Evergreen.V67.Color.Colors
    | SadEmoji Evergreen.V67.Color.Colors
    | Cow Evergreen.V67.Color.Colors
    | Man Evergreen.V67.Color.Colors
    | TileImage Evergreen.V67.Tile.TileGroup Int Evergreen.V67.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V67.Color.Colors
    | DragCursor Evergreen.V67.Color.Colors
    | PinchCursor Evergreen.V67.Color.Colors
    | Line Int Evergreen.V67.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V67.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , to : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V67.Id.Id Evergreen.V67.Id.MailId)
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
    | TextTool (Evergreen.V67.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V67.Id.Id Evergreen.V67.Id.UserId, Evergreen.V67.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V67.Id.Id Evergreen.V67.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , to : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    }
