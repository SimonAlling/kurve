module Rectangle exposing (view)

import Color exposing (Color)
import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector4 exposing (Vec4, vec4)
import WebGL


view : Color -> ( Int, Int ) -> WebGL.Entity
view color ( x, y ) =
    let
        { red, green, blue, alpha } =
            Color.toRgba color

        uniforms : Uniforms
        uniforms =
            { position = vec2 (toFloat x) (toFloat y)
            , size = vec2 3 3
            , window = vec2 559 480
            , color = vec4 red green blue alpha
            }
    in
    WebGL.entity vertex fragment mesh uniforms



-- WebGL Stuff


type alias Attributes =
    { index : Vec2
    }


type alias Uniforms =
    { position : Vec2
    , size : Vec2
    , window : Vec2
    , color : Vec4
    }


type alias Varyings =
    {}


vertex : WebGL.Shader Attributes Uniforms Varyings
vertex =
    [glsl|
uniform vec2 position;
uniform vec2 size;
uniform vec2 window;
attribute vec2 index;

void main () {
  gl_Position =
    vec4(
        (index * size + position)
            / window
            * vec2(2, -2)
            + vec2(-1, 1),
        0.0, 1.0
    );
}
|]


fragment : WebGL.Shader {} Uniforms Varyings
fragment =
    [glsl|
precision mediump float;
uniform vec4 color;

void main () {
  gl_FragColor = color;
}
|]


mesh : WebGL.Mesh Attributes
mesh =
    WebGL.indexedTriangles
        [ { index = vec2 0 0 }
        , { index = vec2 1 0 }
        , { index = vec2 1 1 }
        , { index = vec2 0 1 }
        ]
        [ ( 0, 1, 2 )
        , ( 2, 3, 0 )
        ]
