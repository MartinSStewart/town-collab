module Evergreen.V100.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V100.Animal
import Evergreen.V100.Color
import Evergreen.V100.Coord
import Evergreen.V100.DisplayName
import Evergreen.V100.Id
import Evergreen.V100.Sprite
import Evergreen.V100.Tile
import Pixels


type Image
    = Stamp Evergreen.V100.Color.Colors
    | SunglassesEmoji Evergreen.V100.Color.Colors
    | NormalEmoji Evergreen.V100.Color.Colors
    | SadEmoji Evergreen.V100.Color.Colors
    | Man Evergreen.V100.Color.Colors
    | TileImage Evergreen.V100.Tile.TileGroup Int Evergreen.V100.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V100.Color.Colors
    | DragCursor Evergreen.V100.Color.Colors
    | PinchCursor Evergreen.V100.Color.Colors
    | Line Int Evergreen.V100.Color.Color
    | Animal Evergreen.V100.Animal.AnimalType Evergreen.V100.Color.Colors


type Content
    = ImageType (Evergreen.V100.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V100.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId)
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
    , from : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , to : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , to : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId)
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
    | TextTool (Evergreen.V100.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V100.Id.Id Evergreen.V100.Id.UserId, Evergreen.V100.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
