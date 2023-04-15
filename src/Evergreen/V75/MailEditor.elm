module Evergreen.V75.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V75.Animal
import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.DisplayName
import Evergreen.V75.Id
import Evergreen.V75.Shaders
import Evergreen.V75.Tile
import Pixels


type Image
    = Stamp Evergreen.V75.Color.Colors
    | SunglassesEmoji Evergreen.V75.Color.Colors
    | NormalEmoji Evergreen.V75.Color.Colors
    | SadEmoji Evergreen.V75.Color.Colors
    | Man Evergreen.V75.Color.Colors
    | TileImage Evergreen.V75.Tile.TileGroup Int Evergreen.V75.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V75.Color.Colors
    | DragCursor Evergreen.V75.Color.Colors
    | PinchCursor Evergreen.V75.Color.Colors
    | Line Int Evergreen.V75.Color.Color
    | Animal Evergreen.V75.Animal.AnimalType Evergreen.V75.Color.Colors


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V75.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , to : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V75.Id.Id Evergreen.V75.Id.MailId)
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
    | TextTool (Evergreen.V75.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V75.Id.Id Evergreen.V75.Id.UserId, Evergreen.V75.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V75.Id.Id Evergreen.V75.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , to : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    }
