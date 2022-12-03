module Shaders exposing
    ( DebrisVertex
    , SimpleVertex
    , Vertex
    , blend
    , colorAndTextureFragmentShader
    , colorAndTextureVertexShader
    , colorFragmentShader
    , colorToVec3
    , colorVertexShader
    , debrisVertexShader
    , fragmentShader
    , indexedTriangles
    , simpleFragmentShader
    , simpleVertexShader
    , triangleFan
    , vertexShader
    )

import Color exposing (Color)
import Element
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Shader)
import WebGL.Settings exposing (Setting)
import WebGL.Settings.Blend as Blend
import WebGL.Texture exposing (Texture)


type alias SimpleVertex =
    { position : Vec2 }


type alias Vertex =
    { position : Vec3, texturePosition : Vec2, opacity : Float, primaryColor : Float, secondaryColor : Float }


indexedTriangles : List attributes -> List ( Int, Int, Int ) -> WebGL.Mesh attributes
indexedTriangles vertices indices =
    --let
    --    _ =
    --        Debug.log "new indexedTriangles" ""
    --in
    WebGL.indexedTriangles vertices indices


triangleFan : List attributes -> WebGL.Mesh attributes
triangleFan vertices =
    --let
    --    _ =
    --        Debug.log "new triangleFan" ""
    --in
    WebGL.triangleFan vertices


blend : Setting
blend =
    Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha


colorToVec3 : Element.Color -> Math.Vector3.Vec3
colorToVec3 color =
    let
        { red, green, blue } =
            Element.toRgb color
    in
    Math.Vector3.vec3 red green blue


vertexShader :
    Shader
        Vertex
        { u | view : Mat4, textureSize : Vec2 }
        { vcoord : Vec2
        , opacity2 : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        }
vertexShader =
    [glsl|
attribute vec3 position;
attribute vec2 texturePosition;
attribute float opacity;
attribute float primaryColor;
attribute float secondaryColor;
uniform mat4 view;
uniform vec2 textureSize;
varying vec2 vcoord;
varying float opacity2; 
varying vec3 primaryColor2;
varying vec3 secondaryColor2;

void main () {
    gl_Position = view * vec4(position, 1.0);
    vcoord = texturePosition / textureSize;
    opacity2 = opacity;
    primaryColor2 = vec3(0.0, 0.0, 0.0);
    secondaryColor2 = vec3(0.0, 0.0, 0.0);
}|]


colorVertexShader : Shader { a | position : Vec2 } { u | view : Mat4 } {}
colorVertexShader =
    [glsl|
attribute vec2 position;
uniform mat4 view;

void main () {
    gl_Position = view * vec4(position, 0.0, 1.0);
}|]


colorFragmentShader : Shader {} { u | color : Vec4 } {}
colorFragmentShader =
    [glsl|
precision mediump float;
uniform vec4 color;

void main () {
    gl_FragColor = color;
}|]


colorAndTextureVertexShader : Shader Vertex { a | view : Mat4, textureSize : Vec2 } { vcoord : Vec2 }
colorAndTextureVertexShader =
    [glsl|
attribute vec3 position;
attribute vec2 texturePosition;
uniform vec2 textureSize;
uniform mat4 view;
varying vec2 vcoord;

void main () {
    gl_Position = view * vec4(position, 1.0);
    vcoord = texturePosition / textureSize;
}|]


colorAndTextureFragmentShader : Shader {} { u | color : Vec4, texture : Texture } { vcoord : Vec2 }
colorAndTextureFragmentShader =
    [glsl|
precision mediump float;
uniform vec4 color;
uniform sampler2D texture;
varying vec2 vcoord;

void main () {
    gl_FragColor = texture2D(texture, vcoord) * color;
}|]


simpleVertexShader : Shader SimpleVertex { u | view : Mat4, texturePosition : Vec2, textureScale : Vec2, textureSize : Vec2 } { vcoord : Vec2 }
simpleVertexShader =
    [glsl|
attribute vec2 position;
uniform mat4 view;
uniform vec2 texturePosition;
uniform vec2 textureScale;
uniform vec2 textureSize;
varying vec2 vcoord;

void main () {
    gl_Position = view * vec4(position * textureScale, 0.0, 1.0);
    vcoord = (texturePosition + position * textureScale) / textureSize;
}|]


fragmentShader :
    Shader
        {}
        { u | texture : Texture }
        { vcoord : Vec2
        , opacity2 : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        }
fragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
varying vec2 vcoord;
varying float opacity2;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;

vec3 primaryColor = vec3(1.0, 0.0, 1.0);
vec3 primaryColorShade = vec3(209.0 / 255.0, 64.0 / 255.0, 206.0 / 255.0);
vec3 secondaryColor = vec3(0.0, 1.0, 1.0);
vec3 secondaryColorShade = vec3(96.0 / 255.0, 209.0 / 255.0, 209.0 / 255.0);

void main () {
    vec4 color = texture2D(texture, vcoord);
    if (color.a == 0.0) {
        discard;
    }

    gl_FragColor =
        color.xyz == primaryColor
            ? vec4(primaryColor2, opacity2)
            : color.xyz == primaryColorShade
                ? vec4(primaryColor2 * 0.8, opacity2)
                : color.xyz == secondaryColor
                    ? vec4(secondaryColor2, opacity2)
                    : color.xyz == secondaryColorShade
                        ? vec4(secondaryColor2 * 0.8, opacity2)
                        : vec4(color.xyz, opacity2);
}|]


simpleFragmentShader : Shader {} { u | texture : Texture } { vcoord : Vec2 }
simpleFragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
varying vec2 vcoord;

void main () {
    gl_FragColor = texture2D(texture, vcoord) * vec4(1.0, 1.0, 1.0, 0.5);
}|]


type alias DebrisVertex =
    { position : Vec2
    , texturePosition : Vec2
    , initialSpeed : Vec2
    , startTime : Float
    , primaryColor : Float
    , secondaryColor : Float
    }


debrisVertexShader :
    Shader
        DebrisVertex
        { u | view : Mat4, time : Float, textureSize : Vec2 }
        { vcoord : Vec2
        , opacity2 : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        }
debrisVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 initialSpeed;
attribute vec2 texturePosition;
attribute float startTime;
attribute float primaryColor;
attribute float secondaryColor;
uniform mat4 view;
uniform float time;
uniform vec2 textureSize;
varying vec2 vcoord;
varying float opacity2;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;

void main () {
    float seconds = time - startTime;
    gl_Position = view * vec4(position + vec2(0, 800.0 * seconds * seconds) + initialSpeed * seconds, 0.0, 1.0);
    vcoord = texturePosition / textureSize;
    opacity2 = 1.0;
    primaryColor2 = vec3(0.0, 0.0, 0.0);
    secondaryColor2 = vec3(0.0, 0.0, 0.0);
}|]
