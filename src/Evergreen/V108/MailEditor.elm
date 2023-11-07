module Evergreen.V108.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V108.Animal
import Evergreen.V108.Color
import Evergreen.V108.Coord
import Evergreen.V108.DisplayName
import Evergreen.V108.Id
import Evergreen.V108.Sprite
import Evergreen.V108.Tile
import Pixels


type Image
    = Stamp Evergreen.V108.Color.Colors
    | SunglassesEmoji Evergreen.V108.Color.Colors
    | NormalEmoji Evergreen.V108.Color.Colors
    | SadEmoji Evergreen.V108.Color.Colors
    | Man Evergreen.V108.Color.Colors
    | TileImage Evergreen.V108.Tile.TileGroup Int Evergreen.V108.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V108.Color.Colors
    | DragCursor Evergreen.V108.Color.Colors
    | PinchCursor Evergreen.V108.Color.Colors
    | Line Int Evergreen.V108.Color.Color
    | Animal Evergreen.V108.Animal.AnimalType Evergreen.V108.Color.Colors


type Content
    = ImageType (Evergreen.V108.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V108.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId)
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
    , from : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , to : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , to : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId)
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
    | TextTool (Evergreen.V108.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V108.Id.Id Evergreen.V108.Id.UserId, Evergreen.V108.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
