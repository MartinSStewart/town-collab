module Evergreen.V74.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V74.Animal
import Evergreen.V74.Color
import Evergreen.V74.Coord
import Evergreen.V74.DisplayName
import Evergreen.V74.Id
import Evergreen.V74.Shaders
import Evergreen.V74.Tile
import Pixels


type Image
    = Stamp Evergreen.V74.Color.Colors
    | SunglassesEmoji Evergreen.V74.Color.Colors
    | NormalEmoji Evergreen.V74.Color.Colors
    | SadEmoji Evergreen.V74.Color.Colors
    | Man Evergreen.V74.Color.Colors
    | TileImage Evergreen.V74.Tile.TileGroup Int Evergreen.V74.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V74.Color.Colors
    | DragCursor Evergreen.V74.Color.Colors
    | PinchCursor Evergreen.V74.Color.Colors
    | Line Int Evergreen.V74.Color.Color
    | Animal Evergreen.V74.Animal.AnimalType Evergreen.V74.Color.Colors


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V74.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , to : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V74.Id.Id Evergreen.V74.Id.MailId)
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
    | TextTool (Evergreen.V74.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V74.Id.Id Evergreen.V74.Id.UserId, Evergreen.V74.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V74.Id.Id Evergreen.V74.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , to : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    }
