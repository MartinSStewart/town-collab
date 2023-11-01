module Evergreen.V97.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V97.Animal
import Evergreen.V97.Color
import Evergreen.V97.Coord
import Evergreen.V97.DisplayName
import Evergreen.V97.Id
import Evergreen.V97.Sprite
import Evergreen.V97.Tile
import Pixels


type Image
    = Stamp Evergreen.V97.Color.Colors
    | SunglassesEmoji Evergreen.V97.Color.Colors
    | NormalEmoji Evergreen.V97.Color.Colors
    | SadEmoji Evergreen.V97.Color.Colors
    | Man Evergreen.V97.Color.Colors
    | TileImage Evergreen.V97.Tile.TileGroup Int Evergreen.V97.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V97.Color.Colors
    | DragCursor Evergreen.V97.Color.Colors
    | PinchCursor Evergreen.V97.Color.Colors
    | Line Int Evergreen.V97.Color.Color
    | Animal Evergreen.V97.Animal.AnimalType Evergreen.V97.Color.Colors


type Content
    = ImageType (Evergreen.V97.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V97.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId)
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
    , from : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , to : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , to : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId)
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
    | TextTool (Evergreen.V97.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V97.Id.Id Evergreen.V97.Id.UserId, Evergreen.V97.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
