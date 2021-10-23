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


positionsToGetBetween : Position -> Position -> List Position
positionsToGetBetween ( x1, y1 ) ( x2, y2 ) =
    let
        xDistance =
            x2 - x1

        yDistance =
            y2 - y1

        distance =
            sqrt (xDistance ^ 2 + yDistance ^ 2)

        stepsNeeded =
            (-- The distance is measured in pixels and we want to progress in "1-pixel steps".
             -- This will sometimes be too many (e.g. when going from (0, 0) to (3, 3)), but never too few.
             ceiling distance
            )

        stepIndices =
            List.range 1 stepsNeeded
    in
    List.map
        (\i ->
            let
                t =
                    toFloat i / toFloat stepsNeeded
            in
            ( x1 + xDistance * t
            , y1 + yDistance * t
            )
        )
        stepIndices


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
                    , -- The coordinate system is traditionally "flipped" (wrt standard math) such that the Y axis points downwards.
                      -- Therefore, we have to use minus instead of plus for the Y-axis calculation.
                      y - distanceTraveledSinceLastTick * Angle.sin newDirection
                    )

                newModel =
                    { model
                        | position = newPosition
                        , direction = newDirection
                    }
            in
            ( newModel
            , positionsToGetBetween model.position newPosition
                |> List.map
                    (\position ->
                        render
                            { position = drawingPosition position
                            , thickness = Thickness.toInt theThickness
                            }
                    )
                |> Cmd.batch
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
