module Shaders exposing
    ( DebrisVertex
    , SimpleVertex
    , blend
    , colorFragmentShader
    , colorToVec3
    , colorVertexShader
    , debrisVertexShader
    , fragmentShader
    , simpleFragmentShader
    , simpleVertexShader
    , vertexShader
    )

import Element
import Grid exposing (Vertex)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Shader)
import WebGL.Settings exposing (Setting)
import WebGL.Settings.Blend as Blend
import WebGL.Texture exposing (Texture)


type alias SimpleVertex =
    { position : Vec2 }


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


vertexShader : Shader Grid.Vertex { u | view : Mat4, textureSize : Vec2 } { vcoord : Vec2 }
vertexShader =
    [glsl|
attribute vec3 position;
attribute vec2 texturePosition;
uniform mat4 view;
uniform vec2 textureSize;
varying vec2 vcoord;

void main () {
    gl_Position = view * vec4(position, 1.0);
    vcoord = texturePosition / textureSize;
}

|]


colorVertexShader : Shader { a | position : Vec2 } { u | view : Mat4 } {}
colorVertexShader =
    [glsl|
attribute vec2 position;
uniform mat4 view;

void main () {
    gl_Position = view * vec4(position, 0.0, 1.0);
}

|]


colorFragmentShader : Shader {} { u | color : Vec4 } {}
colorFragmentShader =
    [glsl|
precision mediump float;
uniform vec4 color;

void main () {
    gl_FragColor = color;
}

|]


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
}

|]


fragmentShader : Shader {} { u | texture : Texture } { vcoord : Vec2 }
fragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
varying vec2 vcoord;

void main () {
    vec4 color = texture2D(texture, vcoord);
    if (color.a == 0.0) {
        discard;
    }
    gl_FragColor = color;
}
    |]


simpleFragmentShader : Shader {} { u | texture : Texture } { vcoord : Vec2 }
simpleFragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
varying vec2 vcoord;

void main () {
    gl_FragColor = texture2D(texture, vcoord) * vec4(1.0, 1.0, 1.0, 0.5);
}
    |]


type alias DebrisVertex =
    { position : Vec2, texturePosition : Vec2, initialSpeed : Vec2, startTime : Float }


debrisVertexShader : Shader DebrisVertex { u | view : Mat4, time : Float, textureSize : Vec2 } { vcoord : Vec2 }
debrisVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 initialSpeed;
attribute vec2 texturePosition;
attribute float startTime;
uniform mat4 view;
uniform float time;
uniform vec2 textureSize;
varying vec2 vcoord;

void main () {
    float seconds = time - startTime;
    gl_Position = view * vec4(position + vec2(0, 800.0 * seconds * seconds) + initialSpeed * seconds, 0.0, 1.0);
    vcoord = texturePosition / textureSize;
}

|]
