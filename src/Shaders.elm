module Shaders exposing
    ( DebrisVertex
    , Vertex
    , blend
    , debrisVertexShader
    , fragmentShader
    , indexedTriangles
    , noUserIdSelected
    , opacityAndUserId
    , opaque
    , triangleFan
    , vertexShader
    , worldGenUserId
    , worldMapFragmentShader
    , worldMapVertexShader
    )

import Bitwise
import Effect.WebGL exposing (Shader)
import Effect.WebGL.Settings exposing (Setting)
import Effect.WebGL.Settings.Blend as Blend
import Id exposing (Id, UserId)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL.Texture


type alias Vertex =
    { x : Float
    , y : Float
    , z : Float
    , texturePosition : Float
    , -- bits 0-3 is opacity
      -- bits 4-31 is userId
      opacityAndUserId : Float
    , primaryColor : Float
    , secondaryColor : Float
    }


opaque : number
opaque =
    --0b1111
    15


noUserIdSelected : number
noUserIdSelected =
    -2


worldGenUserId : Id UserId
worldGenUserId =
    Id.fromInt -1


opacityAndUserId : Float -> Id UserId -> Float
opacityAndUserId opacity userId =
    opacity
        * opaque
        |> round
        |> toFloat
        |> (+) (Id.toInt userId |> Bitwise.shiftLeftBy 4 |> toFloat)


indexedTriangles : List attributes -> List ( Int, Int, Int ) -> Effect.WebGL.Mesh attributes
indexedTriangles vertices indices =
    let
        _ =
            Debug.log "new indexedTriangles" ""
    in
    Effect.WebGL.indexedTriangles vertices indices


triangleFan : List attributes -> Effect.WebGL.Mesh attributes
triangleFan vertices =
    let
        _ =
            Debug.log "new triangleFan" ""
    in
    Effect.WebGL.triangleFan vertices


blend : Setting
blend =
    Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha


vertexShader :
    Shader
        Vertex
        { u | view : Mat4, textureSize : Vec2, userId : Float }
        { vcoord : Vec2
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        }
vertexShader =
    [glsl|
attribute float x;
attribute float y;
attribute float z;
attribute float texturePosition;
attribute float opacityAndUserId;
attribute float primaryColor;
attribute float secondaryColor;
uniform mat4 view;
uniform vec2 textureSize;
uniform float userId;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;

int OR(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 || mod(v2, 2.0) > 0.0;

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

vec3 floatColorToVec3(float color) {
    int colorInt = int(color);
    float blue = float(AND(colorInt, 0xFF)) / 255.0;
    float green = float(AND(RShift(colorInt, 8.0), 0xFF)) / 255.0;
    float red = float(AND(RShift(colorInt, 16.0), 0xFF)) / 255.0;
    return vec3(red, green, blue);
}

void main () {
    gl_Position = view * vec4(vec3(x, y, z), 1.0);

    float y = floor(texturePosition / textureSize.x);
    vcoord = vec2(texturePosition - y * textureSize.x, y) / textureSize;
    opacity = float(AND(int(opacityAndUserId), 0xF)) / 16.0;
    isSelected = userId == float(RShift(int(opacityAndUserId), 4.0)) ? 1.0 : 0.0;


    primaryColor2 = floatColorToVec3(primaryColor);
    secondaryColor2 = floatColorToVec3(secondaryColor);
}|]


fragmentShader :
    Shader
        {}
        { u | texture : WebGL.Texture.Texture, color : Vec4 }
        { vcoord : Vec2
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        }
fragmentShader =
    [glsl|
precision mediump float;
uniform sampler2D texture;
uniform vec4 color;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;

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
            ? vec4(primaryColor2, opacity)
            : textureColor.xyz == primaryColorMidShade
                ? vec4(primaryColor2 * 0.9, opacity)
                : textureColor.xyz == primaryColorShade
                    ? vec4(primaryColor2 * 0.8, opacity)
                    : textureColor.xyz == secondaryColor
                        ? vec4(secondaryColor2, opacity)
                        : textureColor.xyz == secondaryColorShade
                            ? vec4(secondaryColor2 * 0.8, opacity)
                            : vec4(textureColor.xyz, opacity)
        ) * color + isSelected * vec4(0.5, 0.5, 0.5, 0.0);
}|]


type alias DebrisVertex =
    { position : Vec2
    , texturePosition : Float
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
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        }
debrisVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 initialSpeed;
attribute float texturePosition;
attribute float startTime;
attribute float primaryColor;
attribute float secondaryColor;
uniform mat4 view;
uniform float time;
uniform vec2 textureSize;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;

int OR(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 || mod(v2, 2.0) > 0.0;

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

vec3 floatColorToVec3(float color) {
    int colorInt = int(color);
    float blue = float(AND(colorInt, 0xFF)) / 255.0;
    float green = float(AND(RShift(colorInt, 8.0), 0xFF)) / 255.0;
    float red = float(AND(RShift(colorInt, 16.0), 0xFF)) / 255.0;
    return vec3(red, green, blue);
}

void main () {
    float seconds = time - startTime;
    gl_Position = view * vec4(position + vec2(0, 800.0 * seconds * seconds) + initialSpeed * seconds, 0.0, 1.0);
    float y = floor(texturePosition / textureSize.x);
    vcoord = vec2(texturePosition - y * textureSize.x, y) / textureSize;
    opacity = 1.0;
    isSelected = 0.0;
    primaryColor2 = floatColorToVec3(primaryColor);
    secondaryColor2 = floatColorToVec3(secondaryColor);
}|]


worldMapVertexShader :
    Shader
        { position : Vec2, vcoord2 : Vec2 }
        { u | view : Mat4 }
        { vcoord : Vec2 }
worldMapVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 vcoord2;
uniform mat4 view;
varying vec2 vcoord;

void main () {
    gl_Position = view * vec4(position, 0.0, 1.0);
    vcoord = vcoord2;
}|]


worldMapFragmentShader : Shader {} { u | texture : WebGL.Texture.Texture, cellPosition : Vec2 } { vcoord : Vec2 }
worldMapFragmentShader =
    [glsl|
precision mediump float;
varying vec2 vcoord;
uniform sampler2D texture;
uniform vec2 cellPosition;

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

ivec2 getCornerOffset2d (float x, float y) {
    return x > y ? ivec2(1, 0) : ivec2(0, 1);
}

int getGrad3(int index) {
    return int(texture2D(texture, vec2(float(index) / 511.0, 2.0 / 2.0)).w * 256.0) - 1;
}

int getPermMod12(int index) {
    return int(texture2D(texture, vec2(float(index) / 511.0, 1.0 / 2.0)).w * 256.0);
}

int getPerm(int index) {
    return int(texture2D(texture, vec2(float(index) / 511.0, 0.0 / 2.0)).w * 256.0);
}

float getN2d (float x, float y, int i, int j) {
    float t = 0.5 - x * x - y * y;
    if (t < 0.0) {
        return 0.0;
    }

    int gi = getPermMod12(i + getPerm(j)) * 3;
    float t_ = t * t;
    return t_ * t_ * (float(getGrad3(gi)) * x + float(getGrad3(gi + 1)) * y);
}

int floor2(float a) {
    return int(floor(a));
}

float noise2d(float xin, float yin) {
    float f2 = 0.5 * (sqrt(3.0) - 1.0);
    float g2 = (3.0 - sqrt(3.0)) / 6.0;
    float s = (xin + yin) * f2;
    int i = floor2(xin + s);
    int j = floor2(yin + s);
    float t = float(i + j) * g2;
    float x0_ = float(i) - t;
    float y0_ = float(j) - t;
    float x0 = xin - x0_;
    float y0 = yin - y0_;
    ivec2 ij1 = getCornerOffset2d(x0, y0);
    int i1 = ij1.x;
    int j1 = ij1.y;
    float x1 = x0 - float(i1) + g2;
    float y1 = y0 - float(j1) + g2;
    float x2 = x0 - 1.0 + 2.0 * g2;
    float y2 = y0 - 1.0 + 2.0 * g2;
    int ii = AND(i, 255);
    int jj = AND(j, 255);
    float n0 = getN2d(x0, y0, ii, jj);
    float n1 = getN2d(x1, y1, (ii + i1), (jj + j1));
    float n2 = getN2d(x2, y2, (ii + 1), (jj + 1));
    return 70.0 * (n0 + n1 + n2);
}



void main () {
    float detail = 4.0;

    vec2 vcoord2 = cellPosition + vcoord;

    float x2 = floor(vcoord2.x * detail) / detail;
    float y2 = floor(vcoord2.y * detail) / detail;

    float terrainDivisionsPerCell = 4.0;
    float persistence = 2.0;
    float persistence2 = 1.0 + persistence;
    float scale = 5.0;
    float scale2 = 14.0 * scale;
    float lowFrequency = noise2d(x2 / scale2, y2 / scale2);
    float highFrequency = noise2d(x2 / scale, y2 / scale);
    float noise1 = highFrequency + (persistence * lowFrequency);
    float value = noise1 / persistence2;
    float value2 = (-highFrequency + (5.0 * lowFrequency)) / 6.0;

    vec4 treeColor = vec4(0.075, 0.471, 0.204, 1.0);
    float colorLevels = 4.0;
    float mix = floor(min(1.0, 8.0 * pow(max(0.0, value), 3.0)) * colorLevels) / colorLevels;

    gl_FragColor =
        vcoord.x > -0.1 && vcoord.y > -0.1 && vcoord.x < 0.1 && vcoord.y < 0.1
            ? vec4(1.0, 1.0, 1.0, 1.0)
            : value <= 0.0
                ? vec4( 0.6, 0.8, 1.0, 1.0)
                : (value2 > 0.45 && value2 < 0.47)
                    ? vec4( 0.6, 0.5, 0.2, 1.0)
                    : vec4( 0.525, 0.796, 0.384, 1.0) * (1.0 - mix) + treeColor * mix;
}|]
