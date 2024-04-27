module Evergreen.V126.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V126.Animal
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.DisplayName
import Evergreen.V126.Id
import Evergreen.V126.Sprite
import Evergreen.V126.Tile
import Pixels


type Image
    = Stamp Evergreen.V126.Color.Colors
    | SunglassesEmoji Evergreen.V126.Color.Colors
    | NormalEmoji Evergreen.V126.Color.Colors
    | SadEmoji Evergreen.V126.Color.Colors
    | Man Evergreen.V126.Color.Colors
    | TileImage Evergreen.V126.Tile.TileGroup Int Evergreen.V126.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V126.Color.Colors
    | DragCursor Evergreen.V126.Color.Colors
    | PinchCursor Evergreen.V126.Color.Colors
    | Line Int Evergreen.V126.Color.Color
    | Animal Evergreen.V126.Animal.AnimalType Evergreen.V126.Color.Colors


type Content
    = ImageType (Evergreen.V126.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V126.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId)
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
    , from : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , to : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , to : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId)
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
    | EraserTool
    | TextTool (Evergreen.V126.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V126.Id.Id Evergreen.V126.Id.UserId, Evergreen.V126.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
