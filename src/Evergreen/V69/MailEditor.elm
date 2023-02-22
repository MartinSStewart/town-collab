module Evergreen.V69.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V69.Color
import Evergreen.V69.Coord
import Evergreen.V69.DisplayName
import Evergreen.V69.Id
import Evergreen.V69.Shaders
import Evergreen.V69.Tile
import Pixels


type Image
    = Stamp Evergreen.V69.Color.Colors
    | SunglassesEmoji Evergreen.V69.Color.Colors
    | NormalEmoji Evergreen.V69.Color.Colors
    | SadEmoji Evergreen.V69.Color.Colors
    | Cow Evergreen.V69.Color.Colors
    | Man Evergreen.V69.Color.Colors
    | TileImage Evergreen.V69.Tile.TileGroup Int Evergreen.V69.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V69.Color.Colors
    | DragCursor Evergreen.V69.Color.Colors
    | PinchCursor Evergreen.V69.Color.Colors
    | Line Int Evergreen.V69.Color.Color


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V69.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , to : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V69.Id.Id Evergreen.V69.Id.MailId)
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
    | TextTool (Evergreen.V69.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V69.Id.Id Evergreen.V69.Id.UserId, Evergreen.V69.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V69.Id.Id Evergreen.V69.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , to : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    }
