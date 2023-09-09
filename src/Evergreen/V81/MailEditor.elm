module Evergreen.V81.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V81.Animal
import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.DisplayName
import Evergreen.V81.Id
import Evergreen.V81.Shaders
import Evergreen.V81.Tile
import Pixels


type Image
    = Stamp Evergreen.V81.Color.Colors
    | SunglassesEmoji Evergreen.V81.Color.Colors
    | NormalEmoji Evergreen.V81.Color.Colors
    | SadEmoji Evergreen.V81.Color.Colors
    | Man Evergreen.V81.Color.Colors
    | TileImage Evergreen.V81.Tile.TileGroup Int Evergreen.V81.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V81.Color.Colors
    | DragCursor Evergreen.V81.Color.Colors
    | PinchCursor Evergreen.V81.Color.Colors
    | Line Int Evergreen.V81.Color.Color
    | Animal Evergreen.V81.Animal.AnimalType Evergreen.V81.Color.Colors


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V81.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , to : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V81.Id.Id Evergreen.V81.Id.MailId)
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
    | TextTool (Evergreen.V81.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V81.Id.Id Evergreen.V81.Id.UserId, Evergreen.V81.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V81.Id.Id Evergreen.V81.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , to : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    }
