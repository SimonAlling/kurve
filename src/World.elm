module World exposing
    ( DrawingPosition
    , Pixel
    , Position
    , desiredPositions
    , distanceBetween
    , distanceToTicks
    , drawingPosition
    )

import Types.Distance as Distance exposing (Distance(..))
import Types.Speed as Speed exposing (Speed)
import Types.Thickness as Thickness exposing (Thickness)
import Types.Tickrate as Tickrate exposing (Tickrate)


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Pixel =
    ( Int, Int )


distanceBetween : Position -> Position -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


distanceToTicks : Tickrate -> Speed -> Distance -> Int
distanceToTicks tickrate speed distance =
    round <| Tickrate.toFloat tickrate * Distance.toFloat distance / Speed.toFloat speed


drawingPosition : Thickness -> Position -> DrawingPosition
drawingPosition thickness ( x, y ) =
    { leftEdge = edgeOfSquare thickness x, topEdge = edgeOfSquare thickness y }


edgeOfSquare : Thickness -> Float -> Int
edgeOfSquare thickness xOrY =
    round (xOrY - (toFloat (Thickness.toInt thickness) / 2))


desiredPositions : Thickness -> Position -> Position -> List Position
desiredPositions thickness position1 position2 =
    let
        maxDistanceBetweenAdjacentPositions =
            -- TODO: Should always be 1?
            (Thickness.toInt thickness |> toFloat) / 2

        totalDistance =
            distanceBetween position1 position2 |> Distance.toFloat

        numberOfSteps =
            floor (totalDistance / maxDistanceBetweenAdjacentPositions)

        stepSize =
            1 / toFloat numberOfSteps

        steps =
            List.range 1 (numberOfSteps - 1)
    in
    List.map (\i -> interpolate position1 position2 (toFloat i * stepSize)) steps ++ [ position2 ]


interpolate : Position -> Position -> Float -> Position
interpolate ( x1, y1 ) ( x2, y2 ) t =
    ( x1 + t * (x2 - x1), y1 + t * (y2 - y1) )
