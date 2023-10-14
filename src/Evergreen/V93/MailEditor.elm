module Evergreen.V93.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V93.Animal
import Evergreen.V93.Color
import Evergreen.V93.Coord
import Evergreen.V93.DisplayName
import Evergreen.V93.Id
import Evergreen.V93.Sprite
import Evergreen.V93.Tile
import Pixels


type Image
    = Stamp Evergreen.V93.Color.Colors
    | SunglassesEmoji Evergreen.V93.Color.Colors
    | NormalEmoji Evergreen.V93.Color.Colors
    | SadEmoji Evergreen.V93.Color.Colors
    | Man Evergreen.V93.Color.Colors
    | TileImage Evergreen.V93.Tile.TileGroup Int Evergreen.V93.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V93.Color.Colors
    | DragCursor Evergreen.V93.Color.Colors
    | PinchCursor Evergreen.V93.Color.Colors
    | Line Int Evergreen.V93.Color.Color
    | Animal Evergreen.V93.Animal.AnimalType Evergreen.V93.Color.Colors


type Content
    = ImageType (Evergreen.V93.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V93.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId)
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
    , from : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , to : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , to : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId)
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
    | TextTool (Evergreen.V93.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V93.Id.Id Evergreen.V93.Id.UserId, Evergreen.V93.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
