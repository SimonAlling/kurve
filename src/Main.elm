port module Main exposing (main)

import Platform exposing (worker)
import Set exposing (Set)
import Time


port render : { x : Int, y : Int } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


{-| A tickrate in ticks per second (Hz).
-}
type Tickrate
    = Tickrate Float


tickrateToFloat : Tickrate -> Float
tickrateToFloat (Tickrate r) =
    r


{-| A speed in kuxels per second.
-}
type Speed
    = Speed Float


speedToFloat : Speed -> Float
speedToFloat (Speed s) =
    s


{-| An angle in radians.
-}
type Angle
    = Angle Float


angleToFloat : Angle -> Float
angleToFloat (Angle a) =
    a


{-| A radius in kuxels.
-}
type Radius
    = Radius Float


radiusToFloat : Radius -> Float
radiusToFloat (Radius r) =
    r


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
    Angle (speedToFloat theSpeed / (tickrateToFloat theTickrate * radiusToFloat theTurningRadius))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            let
                distanceTraveledSinceLastTick =
                    speedToFloat theSpeed / tickrateToFloat theTickrate

                newDirection =
                    if Set.member "m" model.pressedKeys then
                        model.direction + angleToFloat theAngleChange

                    else if Set.member "," model.pressedKeys then
                        model.direction - angleToFloat theAngleChange

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
        [ Time.every (1000 / tickrateToFloat theTickrate) Tick
        , onKeydown KeyWasPressed
        , onKeyup KeyWasReleased
        ]


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
