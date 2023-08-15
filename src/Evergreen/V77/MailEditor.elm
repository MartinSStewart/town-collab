module Evergreen.V77.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V77.Animal
import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.DisplayName
import Evergreen.V77.Id
import Evergreen.V77.Shaders
import Evergreen.V77.Tile
import Pixels


type Image
    = Stamp Evergreen.V77.Color.Colors
    | SunglassesEmoji Evergreen.V77.Color.Colors
    | NormalEmoji Evergreen.V77.Color.Colors
    | SadEmoji Evergreen.V77.Color.Colors
    | Man Evergreen.V77.Color.Colors
    | TileImage Evergreen.V77.Tile.TileGroup Int Evergreen.V77.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V77.Color.Colors
    | DragCursor Evergreen.V77.Color.Colors
    | PinchCursor Evergreen.V77.Color.Colors
    | Line Int Evergreen.V77.Color.Color
    | Animal Evergreen.V77.Animal.AnimalType Evergreen.V77.Color.Colors


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V77.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , to : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V77.Id.Id Evergreen.V77.Id.MailId)
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
    | TextTool (Evergreen.V77.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V77.Id.Id Evergreen.V77.Id.UserId, Evergreen.V77.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , to : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    }
