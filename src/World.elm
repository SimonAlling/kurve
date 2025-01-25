module World exposing
    ( DrawingPosition
    , Pixel
    , Position
    , desiredPixelPositions
    , distanceBetween
    , distanceToTicks
    , drawingPosition
    , toPixel
    )

import RasterShapes
import Thickness exposing (theThickness)
import Types.Distance as Distance exposing (Distance(..))
import Types.Speed as Speed exposing (Speed)
import Types.Tickrate as Tickrate exposing (Tickrate)


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Pixel =
    ( Int, Int )


toPixel : Position -> Pixel
toPixel =
    Tuple.mapBoth floor floor


pixelToRasterShapesPosition : Pixel -> RasterShapes.Position
pixelToRasterShapesPosition ( x, y ) =
    { x = x, y = y }


rasterShapesPositionToPixel : RasterShapes.Position -> Pixel
rasterShapesPositionToPixel { x, y } =
    ( x, y )


distanceBetween : Pixel -> Pixel -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt (toFloat ((x2 - x1) ^ 2 + (y2 - y1) ^ 2))


distanceToTicks : Tickrate -> Speed -> Distance -> Int
distanceToTicks tickrate speed distance =
    round <| Tickrate.toFloat tickrate * Distance.toFloat distance / Speed.toFloat speed


drawingPosition : Pixel -> DrawingPosition
drawingPosition ( x, y ) =
    { leftEdge = edgeOfSquare x, topEdge = edgeOfSquare y }


edgeOfSquare : Int -> Int
edgeOfSquare xOrY =
    xOrY - (theThickness // 2)


desiredPixelPositions : Position -> Position -> List Pixel
desiredPixelPositions position1 position2 =
    let
        startPixel : Pixel
        startPixel =
            toPixel position1

        endPixel : Pixel
        endPixel =
            toPixel position2
    in
    RasterShapes.line
        (pixelToRasterShapesPosition startPixel)
        (pixelToRasterShapesPosition endPixel)
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        -- The first element in the list is the starting position, which is assumed to already have been occupied.
        |> List.drop 1
        |> List.map rasterShapesPositionToPixel
