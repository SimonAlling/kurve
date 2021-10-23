port module Main exposing (main)

import List.Cartesian
import Platform exposing (worker)
import RasterShapes
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
    , occupiedPixels : Set Pixel
    , pressedKeys : Set String
    }


type alias Pixel =
    ( Int, Int )


init : () -> ( Model, Cmd Msg )
init _ =
    let
        position =
            ( 300, 300 )
    in
    ( { position = position
      , direction = Angle 0.5
      , pressedKeys = Set.empty
      , occupiedPixels = pixels (drawingPosition position)
      }
    , render
        { position = drawingPosition position
        , thickness = Thickness.toInt theThickness
        }
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


pixels : DrawingPosition -> Set Pixel
pixels { leftEdge, topEdge } =
    let
        rangeFrom start =
            List.range start (start + Thickness.toInt theThickness - 1)

        xs =
            rangeFrom leftEdge

        ys =
            rangeFrom topEdge
    in
    List.Cartesian.map2 Tuple.pair xs ys
        |> Set.fromList


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


toBresenham : DrawingPosition -> RasterShapes.Position
toBresenham { leftEdge, topEdge } =
    { x = leftEdge, y = topEdge }


fromBresenham : RasterShapes.Position -> DrawingPosition
fromBresenham { x, y } =
    { leftEdge = x, topEdge = y }


drawingPositionsBetween : Position -> Position -> List DrawingPosition
drawingPositionsBetween position1 position2 =
    RasterShapes.line (drawingPosition position1 |> toBresenham) (drawingPosition position2 |> toBresenham)
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        |> List.map fromBresenham


edgeOfSquare : Float -> Int
edgeOfSquare xOrY =
    round (xOrY - (toFloat (Thickness.toInt theThickness) / 2))


drawingPosition : Position -> DrawingPosition
drawingPosition ( x, y ) =
    { leftEdge = edgeOfSquare x, topEdge = edgeOfSquare y }


type Fate
    = Lives
    | Dies


evaluateMove : List DrawingPosition -> Set Pixel -> ( List DrawingPosition, Fate )
evaluateMove positions occupiedPixels =
    let
        checkPositions : List DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Fate )
        checkPositions checked remaining =
            case remaining of
                [] ->
                    ( checked, Lives )

                x :: xs ->
                    let
                        dies =
                            False
                    in
                    if dies then
                        ( checked, Dies )

                    else
                        checkPositions (x :: checked) xs
    in
    Tuple.mapFirst List.reverse <| checkPositions [] positions


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

                desiredDrawingPositions =
                    drawingPositionsBetween model.position newPosition

                ( confirmedDrawingPositions, fate ) =
                    evaluateMove desiredDrawingPositions model.occupiedPixels

                newModel : Model
                newModel =
                    { model
                        | position = newPosition
                        , direction = newDirection
                        , occupiedPixels =
                            confirmedDrawingPositions
                                |> List.foldr
                                    (pixels >> Set.union)
                                    model.occupiedPixels
                    }
            in
            ( newModel
            , confirmedDrawingPositions
                |> List.map
                    (\position ->
                        render
                            { position = position
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
