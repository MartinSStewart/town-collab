module Shaders exposing
    ( DebrisVertex
    , Vertex
    , blend
    , debrisVertexShader
    , fragmentShader
    , indexedTriangles
    , triangleFan
    , vertexShader
    , worldMapFragmentShader
    , worldMapVertexShader
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
