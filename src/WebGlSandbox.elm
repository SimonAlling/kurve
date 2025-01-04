port module WebGlSandbox exposing (..)

{-
   Rotating triangle, that is a "hello world" of the WebGL
-}

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Color
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Rectangle
import Svg
import Svg.Attributes
import WebGL


port requestAnimationFrame : (Float -> msg) -> Sub msg


type alias Model =
    { innerModel : InnerModel
    , deltaSomBlirÖver : Float
    }


type alias InnerModel =
    { position : Int
    }


type alias Msg =
    Float


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( { innerModel = { position = 0 }, deltaSomBlirÖver = 0 }, Cmd.none )
        , view = view
        , subscriptions = \_ -> requestAnimationFrame identity
        , update = update
        }


view : Model -> Html Msg
view model =
    let
        pos =
            ( model.innerModel.position, 5 )

        d =
            pos
                |> (\( x, y ) ->
                        "M" ++ String.fromInt x ++ "," ++ String.fromInt y ++ "h3v3h-3"
                   )
    in
    Svg.svg
        [ width 559
        , height 480
        , style "display" "block"
        ]
        [ Svg.path [ Svg.Attributes.d d, Svg.Attributes.fill "black" ] [] ]


update : Msg -> Model -> ( Model, Cmd Msg )
update frameDelta model =
    let
        ( deltaSomBlirÖver, nyInnerModel ) =
            recurse (frameDelta + model.deltaSomBlirÖver) model.innerModel
    in
    ( { innerModel = nyInnerModel, deltaSomBlirÖver = deltaSomBlirÖver }, Cmd.none )


recurse : Float -> InnerModel -> ( Float, InnerModel )
recurse timeLeftToConsider innerModel =
    if timeLeftToConsider >= timestep then
        let
            newInnerModel =
                reactToTick innerModel
        in
        recurse (timeLeftToConsider - timestep) newInnerModel

    else
        ( timeLeftToConsider
        , innerModel
        )


timestep =
    1000 / 60


reactToTick : InnerModel -> InnerModel
reactToTick innerModel =
    { innerModel | position = innerModel.position + 1 }
