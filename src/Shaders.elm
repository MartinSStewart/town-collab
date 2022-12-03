module Shaders exposing
    ( DebrisVertex
    , Vertex
    , blend
    , debrisVertexShader
    , fragmentShader
    , indexedTriangles
    , triangleFan
    , vertexShader
    )

import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Shader)
import WebGL.Settings exposing (Setting)
import WebGL.Settings.Blend as Blend
import WebGL.Texture exposing (Texture)


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

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

void main () {
    gl_Position = view * vec4(position, 1.0);
    vcoord = texturePosition / textureSize;
    opacity2 = opacity;
    int a = int(primaryColor);
    int b = int(secondaryColor);

    primaryColor2 = vec3(AND(RShift(a, 255.0 * 255.0), 255), AND(RShift(a, 255.0), 255), AND(a, 255));
    secondaryColor2 = vec3(AND(RShift(b, 255.0 * 255.0), 255), AND(RShift(b, 255.0), 255), AND(b, 255));
}|]


fragmentShader :
    Shader
        {}
        { u | texture : Texture, color : Vec4 }
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

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

void main () {
    float seconds = time - startTime;
    gl_Position = view * vec4(position + vec2(0, 800.0 * seconds * seconds) + initialSpeed * seconds, 0.0, 1.0);
    vcoord = texturePosition / textureSize;
    opacity2 = 1.0;

    int a = int(primaryColor);

    primaryColor2 = vec3(AND(RShift(a, 255.0 * 255.0), 255), AND(RShift(a, 255.0), 255), AND(a, 255));
    secondaryColor2 = vec3(AND(RShift(a, 255.0 * 255.0), 255), AND(RShift(a, 255.0), 255), AND(a, 255));
}|]
