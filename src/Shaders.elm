module Shaders exposing (colorToVec3, fragmentShader, vertexShader)

import Element
import Grid
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Shader)
import WebGL.Texture exposing (Texture)


colorToVec3 : Element.Color -> Math.Vector3.Vec3
colorToVec3 color =
    let
        { red, green, blue } =
            Element.toRgb color
    in
    Math.Vector3.vec3 red green blue


vertexShader : Shader Grid.Vertex { u | view : Mat4 } { vcoord : Vec2 }
vertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 texturePosition;
uniform mat4 view;
varying vec2 vcoord;

void main () {
    gl_Position = view * vec4(position, 0.0, 1.0);
    vcoord = texturePosition;
}

|]


fragmentShader : Shader {} { u | texture : Texture, textureSize : Vec2 } { vcoord : Vec2 }
fragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
uniform vec2 textureSize;
varying vec2 vcoord;

void main () {
    gl_FragColor = texture2D(texture, vcoord / textureSize);
}
    |]
