module Evergreen.V60.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V60.Color
import Evergreen.V60.Coord
import Evergreen.V60.DisplayName
import Evergreen.V60.Id
import Evergreen.V60.Shaders
import Evergreen.V60.Tile
import Pixels


type Image
    = Stamp Evergreen.V60.Color.Colors
    | SunglassesEmoji Evergreen.V60.Color.Colors
    | NormalEmoji Evergreen.V60.Color.Colors
    | SadEmoji Evergreen.V60.Color.Colors
    | Cow Evergreen.V60.Color.Colors
    | Man Evergreen.V60.Color.Colors
    | TileImage Evergreen.V60.Tile.TileGroup Int Evergreen.V60.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V60.Color.Colors
    | DragCursor Evergreen.V60.Color.Colors
    | PinchCursor Evergreen.V60.Color.Colors
    | Line Int Evergreen.V60.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V60.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , to : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V60.Id.Id Evergreen.V60.Id.MailId)
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
    | TextTool (Evergreen.V60.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V60.Id.Id Evergreen.V60.Id.UserId, Evergreen.V60.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V60.Id.Id Evergreen.V60.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , to : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    }
