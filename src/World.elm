module World exposing
    ( DrawingPosition
    , Pixel
    , Position
    , desiredDrawingPositions
    , drawingPosition
    , fromBresenham
    , hitbox
    , pixelsToOccupy
    , toBresenham
    )

import Config
import List.Cartesian
import RasterShapes
import Set exposing (Set)
import Types.Thickness as Thickness


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Pixel =
    ( Int, Int )


toBresenham : DrawingPosition -> RasterShapes.Position
toBresenham { leftEdge, topEdge } =
    { x = leftEdge, y = topEdge }


fromBresenham : RasterShapes.Position -> DrawingPosition
fromBresenham { x, y } =
    { leftEdge = x, topEdge = y }


drawingPosition : Position -> DrawingPosition
drawingPosition ( x, y ) =
    { leftEdge = edgeOfSquare x, topEdge = edgeOfSquare y }


edgeOfSquare : Float -> Int
edgeOfSquare xOrY =
    round (xOrY - (toFloat (Thickness.toInt Config.thickness) / 2))


pixelsToOccupy : DrawingPosition -> Set Pixel
pixelsToOccupy { leftEdge, topEdge } =
    let
        rangeFrom start =
            List.range start (start + Thickness.toInt Config.thickness - 1)

        xs =
            rangeFrom leftEdge

        ys =
            rangeFrom topEdge
    in
    List.Cartesian.map2 Tuple.pair xs ys
        |> Set.fromList


desiredDrawingPositions : Position -> Position -> List DrawingPosition
desiredDrawingPositions position1 position2 =
    RasterShapes.line
        (drawingPosition position1 |> toBresenham)
        (drawingPosition position2 |> toBresenham)
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        -- The first element in the list is the starting position, which is assumed to already have been drawn.
        |> List.drop 1
        |> List.map fromBresenham


hitbox : DrawingPosition -> DrawingPosition -> Set Pixel
hitbox oldPosition newPosition =
    let
        is45DegreeDraw =
            oldPosition.leftEdge /= newPosition.leftEdge && oldPosition.topEdge /= newPosition.topEdge

        oldPixels =
            pixelsToOccupy oldPosition

        newPixels =
            pixelsToOccupy newPosition
    in
    if is45DegreeDraw then
        let
            oldXs =
                Set.map Tuple.first oldPixels

            oldYs =
                Set.map Tuple.second oldPixels
        in
        Set.filter (\( x, y ) -> not (Set.member x oldXs) && not (Set.member y oldYs)) newPixels

    else
        Set.diff newPixels oldPixels
