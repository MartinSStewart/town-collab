module Evergreen.V99.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V99.Animal
import Evergreen.V99.Color
import Evergreen.V99.Coord
import Evergreen.V99.DisplayName
import Evergreen.V99.Id
import Evergreen.V99.Sprite
import Evergreen.V99.Tile
import Pixels


type Image
    = Stamp Evergreen.V99.Color.Colors
    | SunglassesEmoji Evergreen.V99.Color.Colors
    | NormalEmoji Evergreen.V99.Color.Colors
    | SadEmoji Evergreen.V99.Color.Colors
    | Man Evergreen.V99.Color.Colors
    | TileImage Evergreen.V99.Tile.TileGroup Int Evergreen.V99.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V99.Color.Colors
    | DragCursor Evergreen.V99.Color.Colors
    | PinchCursor Evergreen.V99.Color.Colors
    | Line Int Evergreen.V99.Color.Color
    | Animal Evergreen.V99.Animal.AnimalType Evergreen.V99.Color.Colors


type Content
    = ImageType (Evergreen.V99.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V99.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }
    | MailDeletedByAdmin
        { previousStatus : MailStatus2
        , deletedAt : Effect.Time.Posix
        }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , to : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , to : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId)
    | TextToolButton
    | ExportButton
    | ImportButton
    | CloseMailViewButton


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
    | TextTool (Evergreen.V99.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V99.Id.Id Evergreen.V99.Id.UserId, Evergreen.V99.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
