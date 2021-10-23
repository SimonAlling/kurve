port module Main exposing (main)

import Platform exposing (worker)
import Set exposing (Set(..))
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))


port render : { x : Int, y : Int } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


type alias Model =
    { x : Float
    , y : Float
    , direction : Float
    , pressedKeys : Set String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { x = 300
      , y = 300
      , direction = 0.5
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
    -- Kuxels (NB: radius, not diameter)
    Radius 28.5


theSpeed : Speed
theSpeed =
    Speed 60


theAngleChange : Angle
theAngleChange =
    Angle (Speed.toFloat theSpeed / (Tickrate.toFloat theTickrate * Radius.toFloat theTurningRadius))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            let
                distanceTraveledSinceLastTick =
                    Speed.toFloat theSpeed / Tickrate.toFloat theTickrate

                newDirection =
                    if Set.member "m" model.pressedKeys then
                        model.direction + Angle.toFloat theAngleChange

                    else if Set.member "," model.pressedKeys then
                        model.direction - Angle.toFloat theAngleChange

                    else
                        model.direction

                newModel =
                    { model
                        | x = model.x + distanceTraveledSinceLastTick * cos newDirection
                        , y = model.y - distanceTraveledSinceLastTick * sin newDirection
                        , direction = newDirection
                    }
            in
            ( newModel
            , render (integerCoordinates { x = newModel.x, y = newModel.y })
            )

        KeyWasPressed key ->
            ( { model | pressedKeys = Set.insert key model.pressedKeys }
            , Cmd.none
            )

        KeyWasReleased key ->
            ( { model | pressedKeys = Set.remove key model.pressedKeys }
            , Cmd.none
            )


integerCoordinates : { x : Float, y : Float } -> { x : Int, y : Int }
integerCoordinates coords =
    { x = round coords.x
    , y = round coords.y
    }


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
