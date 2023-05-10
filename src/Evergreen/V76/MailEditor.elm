module Evergreen.V76.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V76.Animal
import Evergreen.V76.Color
import Evergreen.V76.Coord
import Evergreen.V76.DisplayName
import Evergreen.V76.Id
import Evergreen.V76.Shaders
import Evergreen.V76.Tile
import Pixels


type Image
    = Stamp Evergreen.V76.Color.Colors
    | SunglassesEmoji Evergreen.V76.Color.Colors
    | NormalEmoji Evergreen.V76.Color.Colors
    | SadEmoji Evergreen.V76.Color.Colors
    | Man Evergreen.V76.Color.Colors
    | TileImage Evergreen.V76.Tile.TileGroup Int Evergreen.V76.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V76.Color.Colors
    | DragCursor Evergreen.V76.Color.Colors
    | PinchCursor Evergreen.V76.Color.Colors
    | Line Int Evergreen.V76.Color.Color
    | Animal Evergreen.V76.Animal.AnimalType Evergreen.V76.Color.Colors


type ImageOrText
    = ImageType Image
    | TextType String


type alias Content =
    { position : Evergreen.V76.Coord.Coord Pixels.Pixels
    , item : ImageOrText
    }


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , to : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V76.Id.Id Evergreen.V76.Id.MailId)
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
    | TextTool (Evergreen.V76.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V76.Id.Id Evergreen.V76.Id.UserId, Evergreen.V76.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , to : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    }
