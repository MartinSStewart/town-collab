module Shaders exposing
    ( DebrisVertex
    , Vertex
    , blend
    , colorPickerFragmentShader
    , colorPickerVertexShader
    , debrisVertexShader
    , fragmentShader
    , indexedTriangles
    , triangleFan
    , vertexShader
    )

import Effect.WebGL exposing (Shader)
import Effect.WebGL.Settings exposing (Setting)
import Effect.WebGL.Settings.Blend as Blend
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL.Texture


type alias Vertex =
    { position : Vec3, texturePosition : Vec2, opacity : Float, primaryColor : Vec3, secondaryColor : Vec3 }


indexedTriangles : List attributes -> List ( Int, Int, Int ) -> Effect.WebGL.Mesh attributes
indexedTriangles vertices indices =
    --let
    --    _ =
    --        Debug.log "new indexedTriangles" ""
    --in
    Effect.WebGL.indexedTriangles vertices indices


triangleFan : List attributes -> Effect.WebGL.Mesh attributes
triangleFan vertices =
    --let
    --    _ =
    --        Debug.log "new triangleFan" ""
    --in
    Effect.WebGL.triangleFan vertices


blend : Setting
blend =
    Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha


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
attribute vec3 primaryColor;
attribute vec3 secondaryColor;
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

    primaryColor2 = primaryColor;
    secondaryColor2 = secondaryColor;
}|]


fragmentShader :
    Shader
        {}
        { u | texture : WebGL.Texture.Texture, color : Vec4 }
        { vcoord : Vec2
        , opacity2 : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        }
fragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
uniform vec4 color;
varying vec2 vcoord;
varying float opacity2;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;

vec3 primaryColor = vec3(1.0, 0.0, 1.0);
vec3 primaryColorMidShade = vec3(233.0 / 255.0, 45.0 / 255.0, 231.0 / 255.0);
vec3 primaryColorShade = vec3(209.0 / 255.0, 64.0 / 255.0, 206.0 / 255.0);
vec3 secondaryColor = vec3(0.0, 1.0, 1.0);
vec3 secondaryColorShade = vec3(96.0 / 255.0, 209.0 / 255.0, 209.0 / 255.0);

void main () {
    vec4 textureColor = texture2D(texture, vcoord);
    if (textureColor.a == 0.0) {
        discard;
    }

    gl_FragColor =
        (textureColor.xyz == primaryColor
            ? vec4(primaryColor2, opacity2)
            : textureColor.xyz == primaryColorMidShade
                ? vec4(primaryColor2 * 0.9, opacity2)
                : textureColor.xyz == primaryColorShade
                    ? vec4(primaryColor2 * 0.8, opacity2)
                    : textureColor.xyz == secondaryColor
                        ? vec4(secondaryColor2, opacity2)
                        : textureColor.xyz == secondaryColorShade
                            ? vec4(secondaryColor2 * 0.8, opacity2)
                            : vec4(textureColor.xyz, opacity2)
        ) * color;
}|]


type alias DebrisVertex =
    { position : Vec2
    , texturePosition : Vec2
    , initialSpeed : Vec2
    , startTime : Float
    , primaryColor : Vec3
    , secondaryColor : Vec3
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
attribute vec3 primaryColor;
attribute vec3 secondaryColor;
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

    primaryColor2 = primaryColor;
    secondaryColor2 = secondaryColor;
}|]


colorPickerVertexShader : Shader { position : Vec2, vcoord : Vec2 } { u | view : Mat4 } { vcoord2 : Vec2 }
colorPickerVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 vcoord;
uniform mat4 view;
varying vec2 vcoord2;

void main () {
    gl_Position = view * vec4(position, 0.0, 1.0);
    vcoord2 = vcoord;
}|]


colorPickerFragmentShader : Shader {} a { vcoord2 : Vec2 }
colorPickerFragmentShader =
    [glsl|
precision mediump float;
varying vec2 vcoord2;

void main () {
    gl_FragColor = vec4(vcoord2.x, vcoord2.y, 0.0, 1.0);
}|]
