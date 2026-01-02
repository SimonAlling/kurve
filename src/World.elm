module World exposing
    ( DrawingPosition
    , Pixel
    , Position
    , desiredDrawingPositions
    , distanceBetween
    , distanceToTicks
    , drawingPosition
    , hitbox
    , pixelsToOccupy
    )

import List.Cartesian
import RasterShapes
import Set exposing (Set)
import Thickness exposing (theThickness)
import Types.Distance as Distance exposing (Distance(..))
import Types.Speed as Speed exposing (Speed)
import Types.Tickrate as Tickrate exposing (Tickrate)


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { x : Int, y : Int }


type alias Pixel =
    ( Int, Int )


distanceBetween : Position -> Position -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


distanceToTicks : Tickrate -> Speed -> Distance -> Int
distanceToTicks tickrate speed distance =
    round <| Tickrate.toFloat tickrate * Distance.toFloat distance / Speed.toFloat speed


drawingPosition : Position -> DrawingPosition
drawingPosition ( x, y ) =
    { x = edgeOfSquare x, y = edgeOfSquare y }


edgeOfSquare : Float -> Int
edgeOfSquare xOrY =
    truncate xOrY


pixelsToOccupy : DrawingPosition -> Set Pixel
pixelsToOccupy { x, y } =
    let
        rangeFrom : Int -> List Int
        rangeFrom start =
            List.range start (start + theThickness - 1)

        xs : List Int
        xs =
            rangeFrom x

        ys : List Int
        ys =
            rangeFrom y
    in
    List.Cartesian.map2 Tuple.pair xs ys
        |> Set.fromList


desiredDrawingPositions : Position -> Position -> List DrawingPosition
desiredDrawingPositions position1 position2 =
    RasterShapes.line
        (drawingPosition position1)
        (drawingPosition position2)
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        -- The first element in the list is the starting position, which is assumed to already have been drawn.
        |> List.drop 1


hitbox : DrawingPosition -> DrawingPosition -> Set Pixel
hitbox oldPosition newPosition =
    let
        is45DegreeDraw : Bool
        is45DegreeDraw =
            oldPosition.x /= newPosition.x && oldPosition.y /= newPosition.y

        oldPixels : Set Pixel
        oldPixels =
            pixelsToOccupy oldPosition

        newPixels : Set Pixel
        newPixels =
            pixelsToOccupy newPosition
    in
    if is45DegreeDraw then
        let
            oldXs : Set Int
            oldXs =
                Set.map Tuple.first oldPixels

            oldYs : Set Int
            oldYs =
                Set.map Tuple.second oldPixels
        in
        Set.filter (\( x, y ) -> not (Set.member x oldXs) && not (Set.member y oldYs)) newPixels

    else
        Set.diff newPixels oldPixels
