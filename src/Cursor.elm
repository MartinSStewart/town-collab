module Cursor exposing (Cursor, bounds, draw, fragmentShader, mesh, moveCursor, newLine, position, selection, setCursor, toMesh, updateMesh, vertexShader)

import Bounds exposing (Bounds)
import Coord exposing (Coord)
import Element
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Quantity exposing (Quantity(..))
import Shaders
import Tile
import Units
import WebGL exposing (Shader)
import WebGL.Settings


type Cursor
    = Cursor
        { position : Coord Units.TileUnit
        , startingColumn : Quantity Int Units.TileUnit
        , size : Coord Units.TileUnit
        }


moveCursor : Bool -> ( Quantity Int Units.TileUnit, Quantity Int Units.TileUnit ) -> Cursor -> Cursor
moveCursor isShiftDown offset (Cursor cursor) =
    if isShiftDown then
        Cursor
            { cursor
                | position = Coord.addTuple offset cursor.position
                , size = cursor.size |> Coord.minusTuple offset
            }

    else
        Cursor
            { cursor
                | position = Coord.addTuple offset cursor.position
                , size = ( Units.tileUnit 0, Units.tileUnit 0 )
            }


newLine : Cursor -> Cursor
newLine (Cursor cursor) =
    Cursor
        { position = ( cursor.startingColumn, Tuple.second cursor.position |> Quantity.plus (Units.tileUnit 1) )
        , startingColumn = cursor.startingColumn
        , size = ( Units.tileUnit 0, Units.tileUnit 0 )
        }


setCursor : ( Quantity Int Units.TileUnit, Quantity Int Units.TileUnit ) -> Cursor
setCursor setPosition =
    Cursor
        { position = setPosition
        , startingColumn = Tuple.first setPosition
        , size = ( Units.tileUnit 0, Units.tileUnit 0 )
        }


position : Cursor -> Coord Units.TileUnit
position (Cursor cursor) =
    cursor.position


mesh : Int -> Float -> Float -> Float -> Float -> ( List { position : Vec2 }, List ( Int, Int, Int ) )
mesh indexOffset x y w h =
    ( [ { position = Math.Vector2.vec2 x y }
      , { position = Math.Vector2.vec2 (x + w) y }
      , { position = Math.Vector2.vec2 (x + w) (y + h) }
      , { position = Math.Vector2.vec2 x (y + h) }
      ]
    , [ ( indexOffset, indexOffset + 3, indexOffset + 1 ), ( indexOffset + 2, indexOffset + 1, indexOffset + 3 ) ]
    )


toMesh : Cursor -> WebGL.Mesh { position : Vec2 }
toMesh cursor =
    let
        thickness =
            3

        ( cw, ch ) =
            size cursor
                |> Coord.toRawCoord
                |> Tuple.mapBoth (abs >> (+) 1) (abs >> (+) 1)

        ( cw_, ch_ ) =
            size cursor |> Coord.toRawCoord

        ( w, h ) =
            Coord.toRawCoord Tile.size

        ( v0, i0 ) =
            mesh 0
                (if cw_ > 0 then
                    0

                 else
                    toFloat <| abs cw_ * w
                )
                (if ch_ > 0 then
                    0

                 else
                    toFloat <| abs ch_ * h
                )
                (toFloat w)
                (toFloat h)

        ( v1, i1 ) =
            mesh 4 0 0 thickness (toFloat <| ch * h)

        ( v2, i2 ) =
            mesh 8 (toFloat <| cw * w - thickness) 0 thickness (toFloat <| ch * h)

        ( v3, i3 ) =
            mesh 12 0 0 (toFloat <| cw * w) thickness

        ( v4, i4 ) =
            mesh 16 0 (toFloat <| ch * h - thickness) (toFloat <| cw * w) thickness
    in
    WebGL.indexedTriangles
        (v0 ++ v1 ++ v2 ++ v3 ++ v4)
        (i0 ++ i1 ++ i2 ++ i3 ++ i4)


updateMesh :
    { a | cursor : Cursor, cursorMesh : WebGL.Mesh { position : Vec2 } }
    -> { a | cursor : Cursor, cursorMesh : WebGL.Mesh { position : Vec2 } }
    -> { a | cursor : Cursor, cursorMesh : WebGL.Mesh { position : Vec2 } }
updateMesh oldModel newModel =
    if size oldModel.cursor == size newModel.cursor then
        newModel

    else
        { newModel | cursorMesh = toMesh newModel.cursor }


size : Cursor -> Coord Units.TileUnit
size (Cursor cursor) =
    cursor.size


selection : Coord Units.TileUnit -> Coord Units.TileUnit -> Cursor
selection start end =
    { position = end
    , size = Coord.minusTuple end start
    , startingColumn = Quantity.min (Tuple.first start) (Tuple.first end)
    }
        |> Cursor


bounds : Cursor -> Bounds Units.TileUnit
bounds (Cursor cursor) =
    let
        pos0 =
            cursor.position

        pos1 =
            Coord.addTuple cursor.position cursor.size
    in
    Bounds.bounds
        (Coord.minTuple pos0 pos1)
        (Coord.maxTuple pos0 pos1)


draw : Mat4 -> Element.Color -> { a | cursor : Cursor, cursorMesh : WebGL.Mesh { position : Vec2 } } -> WebGL.Entity
draw viewMatrix color model =
    WebGL.entityWith
        [ WebGL.Settings.cullFace WebGL.Settings.back ]
        vertexShader
        fragmentShader
        model.cursorMesh
        { view = viewMatrix
        , offset = bounds model.cursor |> Bounds.minimum |> Units.tileToWorld |> Coord.coordToVec
        , color = Shaders.colorToVec3 color
        }


vertexShader : Shader { position : Vec2 } { u | view : Mat4, offset : Vec2 } {}
vertexShader =
    [glsl|

attribute vec2 position;
uniform mat4 view;
uniform vec2 offset;

void main () {
  gl_Position = view * vec4(position + offset, 0.0, 1.0);
}

|]


fragmentShader : Shader {} { u | color : Vec3 } {}
fragmentShader =
    [glsl|
        precision mediump float;
        uniform vec3 color;
        void main () {
            gl_FragColor = vec4(color, 1.0);
        }
    |]
