module World exposing
    ( DrawingPosition
    , Position
    , desiredPositions
    , distanceBetween
    , distanceToTicks
    , drawingPosition
    )

import Thickness exposing (theThickness)
import Types.Distance as Distance exposing (Distance(..))
import Types.Speed as Speed exposing (Speed)
import Types.Tickrate as Tickrate exposing (Tickrate)


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


distanceBetween : Position -> Position -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


distanceToTicks : Tickrate -> Speed -> Distance -> Int
distanceToTicks tickrate speed distance =
    round <| Tickrate.toFloat tickrate * Distance.toFloat distance / Speed.toFloat speed


drawingPosition : Position -> DrawingPosition
drawingPosition ( x, y ) =
    { leftEdge = edgeOfSquare x, topEdge = edgeOfSquare y }


edgeOfSquare : Float -> Int
edgeOfSquare xOrY =
    round (xOrY - (theThickness / 2))


desiredPositions : Position -> Position -> List Position
desiredPositions position1 position2 =
    let
        maxDistanceBetweenAdjacentPositions : Float
        maxDistanceBetweenAdjacentPositions =
            -- Must be 1 at least as long as we use these positions for drawing.
            -- Otherwise a low tickrate, like 5, makes it obvious that the squares that make up the Kurve aren't drawn densely enough.
            -- Tested with 45-degree Kurves starting from ( 50, 50.5 ), ( 50, 70.1 ) and ( 50, 90 ).
            1

        totalDistance : Float
        totalDistance =
            distanceBetween position1 position2 |> Distance.toFloat

        numberOfSteps : Int
        numberOfSteps =
            floor (totalDistance / maxDistanceBetweenAdjacentPositions)

        stepSize : Float
        stepSize =
            1 / toFloat numberOfSteps

        steps : List Int
        steps =
            List.range 1 (numberOfSteps - 1)
    in
    List.map (\i -> interpolate position1 position2 (toFloat i * stepSize)) steps ++ [ position2 ]


interpolate : Position -> Position -> Float -> Position
interpolate ( x1, y1 ) ( x2, y2 ) t =
    ( x1 + t * (x2 - x1), y1 + t * (y2 - y1) )
