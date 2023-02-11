module Evergreen.V58.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V58.Color
import Evergreen.V58.Coord
import Evergreen.V58.DisplayName
import Evergreen.V58.Id
import Evergreen.V58.Shaders
import Evergreen.V58.Tile
import Pixels


type Image
    = Stamp Evergreen.V58.Color.Colors
    | SunglassesEmoji Evergreen.V58.Color.Colors
    | NormalEmoji Evergreen.V58.Color.Colors
    | SadEmoji Evergreen.V58.Color.Colors
    | Cow Evergreen.V58.Color.Colors
    | Man Evergreen.V58.Color.Colors
    | TileImage Evergreen.V58.Tile.TileGroup Int Evergreen.V58.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V58.Color.Colors
    | DragCursor Evergreen.V58.Color.Colors
    | PinchCursor Evergreen.V58.Color.Colors
    | Line Int Evergreen.V58.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V58.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , to : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V58.Id.Id Evergreen.V58.Id.MailId)
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
    | TextTool (Evergreen.V58.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V58.Id.Id Evergreen.V58.Id.UserId, Evergreen.V58.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V58.Id.Id Evergreen.V58.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , to : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    }
