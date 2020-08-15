module Cursor exposing (Cursor, bounds, draw, fragmentShader, mesh, moveCursor, newLine, position, setCursor, vertexShader)

import Ascii
import Helper exposing (Coord)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Quantity exposing (Quantity(..))
import Units
import WebGL exposing (Shader)


type Cursor
    = Cursor
        { position : Coord Units.AsciiUnit
        , startingColumn : Quantity Int Units.AsciiUnit
        , size : Coord Units.AsciiUnit
        }


moveCursor : Bool -> ( Quantity Int Units.AsciiUnit, Quantity Int Units.AsciiUnit ) -> Cursor -> Cursor
moveCursor isShiftDown offset (Cursor cursor) =
    if isShiftDown then
        Cursor
            { cursor
                | position = Helper.addTuple offset cursor.position
                , size = cursor.size |> Helper.minusTuple offset
            }

    else
        Cursor
            { cursor
                | position = Helper.addTuple offset cursor.position
                , size = ( Units.asciiUnit 0, Units.asciiUnit 0 )
            }


newLine : Cursor -> Cursor
newLine (Cursor cursor) =
    Cursor
        { position = ( cursor.startingColumn, Tuple.second cursor.position |> Quantity.plus (Units.asciiUnit 1) )
        , startingColumn = cursor.startingColumn
        , size = ( Units.asciiUnit 0, Units.asciiUnit 0 )
        }


setCursor : ( Quantity Int Units.AsciiUnit, Quantity Int Units.AsciiUnit ) -> Cursor
setCursor setPosition =
    Cursor
        { position = setPosition
        , startingColumn = Tuple.first setPosition
        , size = ( Units.asciiUnit 0, Units.asciiUnit 0 )
        }


position : Cursor -> Coord Units.AsciiUnit
position (Cursor cursor) =
    cursor.position


mesh : WebGL.Mesh { position : Vec2 }
mesh =
    let
        ( Quantity w, Quantity h ) =
            Ascii.size
    in
    [ { position = Math.Vector2.vec2 0 0 }
    , { position = Math.Vector2.vec2 w 0 }
    , { position = Math.Vector2.vec2 w h }
    , { position = Math.Vector2.vec2 0 h }
    ]
        |> WebGL.triangleFan


bounds : Cursor -> { min : Coord Units.AsciiUnit, max : Coord Units.AsciiUnit }
bounds (Cursor cursor) =
    let
        pos0 =
            cursor.position

        pos1 =
            Helper.addTuple cursor.position cursor.size
    in
    { min = Helper.minTuple pos0 pos1
    , max = Helper.maxTuple pos0 pos1 |> Helper.addTuple ( Units.asciiUnit 1, Units.asciiUnit 1 )
    }


draw : Mat4 -> Cursor -> WebGL.Entity
draw viewMatrix cursor =
    let
        bounds_ =
            bounds cursor

        ( minX, minY ) =
            Helper.rawCoord bounds_.min

        ( maxX, maxY ) =
            Helper.rawCoord bounds_.max
    in
    WebGL.entity
        vertexShader
        fragmentShader
        mesh
        { view = viewMatrix
        , offset = bounds_.min |> Units.asciiToWorld |> Helper.coordToVec
        , color = Math.Vector3.vec3 1 1 0
        , size = Math.Vector2.vec2 (toFloat (maxX - minX)) (toFloat (maxY - minY))
        }


vertexShader : Shader { position : Vec2 } { u | view : Mat4, offset : Vec2, size : Vec2 } {}
vertexShader =
    [glsl|

attribute vec2 position;
uniform mat4 view;
uniform vec2 offset;
uniform vec2 size;

void main () {
  gl_Position = view * vec4(position * size + offset, 0.0, 1.0);
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
