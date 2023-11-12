module Evergreen.V112.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V112.Animal
import Evergreen.V112.Color
import Evergreen.V112.Coord
import Evergreen.V112.DisplayName
import Evergreen.V112.Id
import Evergreen.V112.Sprite
import Evergreen.V112.Tile
import Pixels


type Image
    = Stamp Evergreen.V112.Color.Colors
    | SunglassesEmoji Evergreen.V112.Color.Colors
    | NormalEmoji Evergreen.V112.Color.Colors
    | SadEmoji Evergreen.V112.Color.Colors
    | Man Evergreen.V112.Color.Colors
    | TileImage Evergreen.V112.Tile.TileGroup Int Evergreen.V112.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V112.Color.Colors
    | DragCursor Evergreen.V112.Color.Colors
    | PinchCursor Evergreen.V112.Color.Colors
    | Line Int Evergreen.V112.Color.Color
    | Animal Evergreen.V112.Animal.AnimalType Evergreen.V112.Color.Colors


type Content
    = ImageType (Evergreen.V112.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V112.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId)
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
    , from : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , to : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , to : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId)
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
    | TextTool (Evergreen.V112.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V112.Id.Id Evergreen.V112.Id.UserId, Evergreen.V112.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
