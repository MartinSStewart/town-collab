module Evergreen.V62.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V62.Color
import Evergreen.V62.Coord
import Evergreen.V62.DisplayName
import Evergreen.V62.Id
import Evergreen.V62.Shaders
import Evergreen.V62.Tile
import Pixels


type Image
    = Stamp Evergreen.V62.Color.Colors
    | SunglassesEmoji Evergreen.V62.Color.Colors
    | NormalEmoji Evergreen.V62.Color.Colors
    | SadEmoji Evergreen.V62.Color.Colors
    | Cow Evergreen.V62.Color.Colors
    | Man Evergreen.V62.Color.Colors
    | TileImage Evergreen.V62.Tile.TileGroup Int Evergreen.V62.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V62.Color.Colors
    | DragCursor Evergreen.V62.Color.Colors
    | PinchCursor Evergreen.V62.Color.Colors
    | Line Int Evergreen.V62.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V62.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , to : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V62.Id.Id Evergreen.V62.Id.MailId)
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
    | TextTool (Evergreen.V62.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V62.Id.Id Evergreen.V62.Id.UserId, Evergreen.V62.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V62.Id.Id Evergreen.V62.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , to : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    }
