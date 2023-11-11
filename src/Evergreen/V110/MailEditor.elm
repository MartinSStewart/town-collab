module Evergreen.V110.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V110.Animal
import Evergreen.V110.Color
import Evergreen.V110.Coord
import Evergreen.V110.DisplayName
import Evergreen.V110.Id
import Evergreen.V110.Sprite
import Evergreen.V110.Tile
import Pixels


type Image
    = Stamp Evergreen.V110.Color.Colors
    | SunglassesEmoji Evergreen.V110.Color.Colors
    | NormalEmoji Evergreen.V110.Color.Colors
    | SadEmoji Evergreen.V110.Color.Colors
    | Man Evergreen.V110.Color.Colors
    | TileImage Evergreen.V110.Tile.TileGroup Int Evergreen.V110.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V110.Color.Colors
    | DragCursor Evergreen.V110.Color.Colors
    | PinchCursor Evergreen.V110.Color.Colors
    | Line Int Evergreen.V110.Color.Color
    | Animal Evergreen.V110.Animal.AnimalType Evergreen.V110.Color.Colors


type Content
    = ImageType (Evergreen.V110.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V110.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V110.Id.Id Evergreen.V110.Id.TrainId)
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
    , from : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , to : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , to : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId)
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
    | TextTool (Evergreen.V110.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V110.Id.Id Evergreen.V110.Id.UserId, Evergreen.V110.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
