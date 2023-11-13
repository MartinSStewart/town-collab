module Evergreen.V113.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V113.Animal
import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.DisplayName
import Evergreen.V113.Id
import Evergreen.V113.Sprite
import Evergreen.V113.Tile
import Pixels


type Image
    = Stamp Evergreen.V113.Color.Colors
    | SunglassesEmoji Evergreen.V113.Color.Colors
    | NormalEmoji Evergreen.V113.Color.Colors
    | SadEmoji Evergreen.V113.Color.Colors
    | Man Evergreen.V113.Color.Colors
    | TileImage Evergreen.V113.Tile.TileGroup Int Evergreen.V113.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V113.Color.Colors
    | DragCursor Evergreen.V113.Color.Colors
    | PinchCursor Evergreen.V113.Color.Colors
    | Line Int Evergreen.V113.Color.Color
    | Animal Evergreen.V113.Animal.AnimalType Evergreen.V113.Color.Colors


type Content
    = ImageType (Evergreen.V113.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V113.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId)
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
    , from : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , to : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , to : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId)
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
    | TextTool (Evergreen.V113.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V113.Id.Id Evergreen.V113.Id.UserId, Evergreen.V113.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
