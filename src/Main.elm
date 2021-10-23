port module Main exposing (main)

import Platform exposing (worker)
import Set exposing (Set(..))
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))


port render : { position : DrawingPosition, thickness : Int } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


type alias Model =
    { position : Position
    , direction : Angle
    , pressedKeys : Set String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { position = ( 300, 300 )
      , direction = Angle 0.5
      , pressedKeys = Set.empty
      }
    , Cmd.none
    )


type Msg
    = Tick Time.Posix
    | KeyWasPressed String
    | KeyWasReleased String


theTickrate : Tickrate
theTickrate =
    Tickrate 60


theTurningRadius : Radius
theTurningRadius =
    Radius 28.5


theSpeed : Speed
theSpeed =
    Speed 60


theThickness : Thickness
theThickness =
    Thickness 3


theAngleChange : Angle
theAngleChange =
    Angle (Speed.toFloat theSpeed / (Tickrate.toFloat theTickrate * Radius.toFloat theTurningRadius))


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    ( Int
    , Int
    )


drawingPosition : Position -> DrawingPosition
drawingPosition ( x, y ) =
    let
        edgeOfSquare xOrY =
            round (xOrY - (toFloat (Thickness.toInt theThickness) / 2))
    in
    ( edgeOfSquare x, edgeOfSquare y )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            let
                distanceTraveledSinceLastTick =
                    Speed.toFloat theSpeed / Tickrate.toFloat theTickrate

                newDirection =
                    if Set.member "ArrowLeft" model.pressedKeys then
                        Angle.add model.direction theAngleChange

                    else if Set.member "ArrowDown" model.pressedKeys then
                        Angle.add model.direction (Angle.negate theAngleChange)

                    else
                        model.direction

                ( x, y ) =
                    model.position

                newPosition =
                    ( x + distanceTraveledSinceLastTick * Angle.cos newDirection
                    , y - distanceTraveledSinceLastTick * Angle.sin newDirection
                    )

                newModel =
                    { model
                        | position = newPosition
                        , direction = newDirection
                    }
            in
            ( newModel
            , render
                { position = drawingPosition newPosition
                , thickness = Thickness.toInt theThickness
                }
            )

        KeyWasPressed key ->
            ( { model | pressedKeys = Set.insert key model.pressedKeys }
            , Cmd.none
            )

        KeyWasReleased key ->
            ( { model | pressedKeys = Set.remove key model.pressedKeys }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every (1000 / Tickrate.toFloat theTickrate) Tick
        , onKeydown KeyWasPressed
        , onKeyup KeyWasReleased
        ]


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
