module Mail exposing
    ( BackendMail
    , FrontendMail
    , Image(..)
    , MailEditor
    , MailEditorData
    , MailStatus(..)
    , drawMail
    , getImageData
    , initEditor
    , initEditorData
    , mouseDownMailEditor
    )

import Coord exposing (Coord)
import Frame2d
import Grid exposing (Vertex)
import Id exposing (Id, TrainId, UserId)
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (SimpleVertex)
import Tile
import Units exposing (MailPixelUnit)
import Vector2d
import WebGL
import WebGL.Settings.Blend as Blend
import WebGL.Texture


type alias BackendMail =
    { message : String
    , status : MailStatus
    , sender : Id UserId
    , recipient : Id UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , sender : Id UserId
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Id TrainId)
    | MailReceived


type alias MailEditor =
    { recipient : Maybe (Id UserId)
    , content : List { position : Coord MailPixelUnit, image : Image }
    , mesh : WebGL.Mesh Vertex
    , currentImage : Image
    }


type alias MailEditorData =
    { recipient : Maybe (Id UserId)
    , content : List { position : Coord MailPixelUnit, image : Image }
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


initEditor : MailEditorData -> MailEditor
initEditor data =
    { recipient = data.recipient
    , content = data.content
    , mesh = mesh data.content
    , currentImage = BlueStamp
    }


mesh : List { position : Coord MailPixelUnit, image : Image } -> WebGL.Mesh Vertex
mesh content =
    WebGL.indexedTriangles
        (mailMesh ++ List.concatMap imageMesh content)
        (List.range 0 (List.length content) |> List.concatMap Grid.getIndices)


initEditorData : MailEditorData
initEditorData =
    { recipient = Nothing
    , content = []
    }


getImageData : Image -> { textureSize : ( Int, Int ), texturePosition : ( Int, Int ) }
getImageData image =
    case image of
        BlueStamp ->
            { textureSize = ( 28, 28 ), texturePosition = ( 504, 0 ) }

        SunglassesSmiley ->
            { textureSize = ( 24, 24 ), texturePosition = ( 532, 0 ) }

        NormalSmiley ->
            { textureSize = ( 24, 24 ), texturePosition = ( 556, 0 ) }


mouseDownMailEditor :
    Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> Point2d Pixels Pixels
    -> MailEditor
    -> MailEditor
mouseDownMailEditor windowWidth windowHeight config mousePosition mailEditor =
    let
        mailCoord =
            screenToWorld windowWidth windowHeight config mousePosition
                |> Coord.roundPoint
                |> Coord.minusTuple
                    (Coord.fromTuple imageData.textureSize
                        |> Coord.divideTuple (Coord.fromTuple ( 2, 2 ))
                    )

        imageData =
            getImageData mailEditor.currentImage

        newContent =
            mailEditor.content ++ [ { position = mailCoord, image = BlueStamp } ]
    in
    { mailEditor
        | content = newContent
        , mesh = mesh newContent
    }


mailWidth =
    270


mailHeight =
    144


mailMesh : List Vertex
mailMesh =
    let
        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels ( 234, 0 ) ( mailWidth, mailHeight )
    in
    [ { position = Vec2.vec2 0 0, texturePosition = topLeft }
    , { position = Vec2.vec2 mailWidth 0, texturePosition = topRight }
    , { position = Vec2.vec2 mailWidth mailHeight, texturePosition = bottomRight }
    , { position = Vec2.vec2 0 mailHeight, texturePosition = bottomLeft }
    ]


mailZoomFactor : Int -> Int -> Int
mailZoomFactor windowWidth windowHeight =
    min
        (toFloat windowWidth / (30 + mailWidth))
        (toFloat windowHeight / (30 + mailHeight))
        |> floor


screenToWorld :
    Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> Point2d Pixels Pixels
    -> Point2d MailPixelUnit MailPixelUnit
screenToWorld windowWidth windowHeight model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> Point2d.at (scaleForScreenToWorld windowWidth windowHeight model)
        >> Point2d.placeIn (Point2d.unsafe { x = mailWidth / 2, y = mailHeight / 2 } |> Frame2d.atPoint)


worldToScreen :
    Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> Point2d MailPixelUnit MailPixelUnit
    -> Point2d Pixels Pixels
worldToScreen windowWidth windowHeight model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5 |> Vector2d.reverse)
        << Point2d.at_ (scaleForScreenToWorld windowWidth windowHeight model)
        << Point2d.relativeTo (Point2d.unsafe { x = mailWidth / 2, y = mailHeight / 2 } |> Frame2d.atPoint)


scaleForScreenToWorld windowWidth windowHeight model =
    model.devicePixelRatio / toFloat (mailZoomFactor windowWidth windowHeight) |> Quantity


drawMail :
    WebGL.Texture.Texture
    -> Point2d Pixels Pixels
    -> Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> MailEditor
    -> List WebGL.Entity
drawMail texture mousePosition windowWidth windowHeight config mailEditor =
    let
        zoomFactor : Float
        zoomFactor =
            mailZoomFactor windowWidth windowHeight |> toFloat

        ( mouseX, mouseY ) =
            screenToWorld windowWidth windowHeight config mousePosition |> Coord.roundPoint |> Coord.toTuple

        imageData =
            getImageData mailEditor.currentImage

        ( width, height ) =
            imageData.textureSize

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels imageData.texturePosition ( width, height )
    in
    WebGL.entityWith
        [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha ]
        Shaders.vertexShader
        Shaders.fragmentShader
        mailEditor.mesh
        { texture = texture
        , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
        , view =
            Mat4.makeScale3
                (zoomFactor * 2 / toFloat windowWidth)
                (zoomFactor * -2 / toFloat windowHeight)
                1
                |> Mat4.translate3
                    (mailWidth / -2 |> round |> toFloat)
                    (mailHeight / -2 |> round |> toFloat)
                    0
        }
        :: [ WebGL.entityWith
                [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha ]
                Shaders.simpleVertexShader
                Shaders.simpleFragmentShader
                square
                { texture = texture
                , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                , texturePosition = Coord.fromTuple imageData.texturePosition |> Coord.toVec2
                , textureScale = Coord.fromTuple imageData.textureSize |> Coord.toVec2
                , view =
                    Mat4.makeScale3
                        (zoomFactor * 2 / toFloat windowWidth)
                        (zoomFactor * -2 / toFloat windowHeight)
                        1
                        |> Mat4.translate3
                            (toFloat mouseX + toFloat (width // -2) + mailWidth / -2 |> round |> toFloat)
                            (toFloat mouseY + toFloat (height // -2) + mailHeight / -2 |> round |> toFloat)
                            0
                }
           ]


imageMesh : { position : Coord MailPixelUnit, image : Image } -> List Vertex
imageMesh { position, image } =
    let
        imageData =
            getImageData image

        ( width, height ) =
            imageData.textureSize

        ( Quantity x, Quantity y ) =
            position

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels imageData.texturePosition ( width, height )
    in
    [ { position = Vec2.vec2 (toFloat x) (toFloat y), texturePosition = topLeft }
    , { position = Vec2.vec2 (toFloat (x + width)) (toFloat y), texturePosition = topRight }
    , { position = Vec2.vec2 (toFloat (x + width)) (toFloat (y + height)), texturePosition = bottomRight }
    , { position = Vec2.vec2 (toFloat x) (toFloat (y + height)), texturePosition = bottomLeft }
    ]


square : WebGL.Mesh SimpleVertex
square =
    WebGL.triangleFan
        [ { position = Vec2.vec2 0 0 }
        , { position = Vec2.vec2 1 0 }
        , { position = Vec2.vec2 1 1 }
        , { position = Vec2.vec2 0 1 }
        ]
