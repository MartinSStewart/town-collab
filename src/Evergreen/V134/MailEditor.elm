module Evergreen.V134.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V134.Animal
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.DisplayName
import Evergreen.V134.Id
import Evergreen.V134.Sprite
import Evergreen.V134.Tile
import Pixels


type Image
    = Stamp Evergreen.V134.Color.Colors
    | SunglassesEmoji Evergreen.V134.Color.Colors
    | NormalEmoji Evergreen.V134.Color.Colors
    | SadEmoji Evergreen.V134.Color.Colors
    | Man Evergreen.V134.Color.Colors
    | TileImage Evergreen.V134.Tile.TileGroup Int Evergreen.V134.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V134.Color.Colors
    | DragCursor Evergreen.V134.Color.Colors
    | PinchCursor Evergreen.V134.Color.Colors
    | Line Int Evergreen.V134.Color.Color
    | Animal Evergreen.V134.Animal.AnimalType Evergreen.V134.Color.Colors


type Content
    = ImageType (Evergreen.V134.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V134.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId)
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
    , from : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , to : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , to : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId)
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
    | TextTool (Evergreen.V134.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V134.Id.Id Evergreen.V134.Id.UserId, Evergreen.V134.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
