module World exposing
    ( DrawingPosition
    , Pixel
    , Position
    , desiredDrawingPositions
    , distanceToTicks
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
import Types.Distance as Distance exposing (Distance(..))
import Types.Speed as Speed exposing (Speed)
import Types.Thickness as Thickness
import Types.Tickrate as Tickrate


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Pixel =
    ( Int, Int )


distanceToTicks : Speed -> Distance -> Int
distanceToTicks speed distance =
    round <| Tickrate.toFloat Config.tickrate * Distance.toFloat distance / Speed.toFloat speed


toBresenham : DrawingPosition -> RasterShapes.Position
toBresenham { leftEdge, topEdge } =
    { x = leftEdge, y = topEdge }


fromBresenham : RasterShapes.Position -> DrawingPosition
fromBresenham { x, y } =
    { leftEdge = x, topEdge = y }


drawingPosition : Thickness.Thickness -> Position -> DrawingPosition
drawingPosition thickness ( x, y ) =
    { leftEdge = edgeOfSquare thickness x, topEdge = edgeOfSquare thickness y }


edgeOfSquare : Thickness.Thickness -> Float -> Int
edgeOfSquare thickness xOrY =
    round (xOrY - (toFloat (Thickness.toInt thickness) / 2))


pixelsToOccupy : Thickness.Thickness -> DrawingPosition -> Set Pixel
pixelsToOccupy thickness { leftEdge, topEdge } =
    let
        rangeFrom start =
            List.range start (start + Thickness.toInt thickness - 1)

        xs =
            rangeFrom leftEdge

        ys =
            rangeFrom topEdge
    in
    List.Cartesian.map2 Tuple.pair xs ys
        |> Set.fromList


desiredDrawingPositions : Thickness.Thickness -> Position -> Position -> List DrawingPosition
desiredDrawingPositions thickness position1 position2 =
    RasterShapes.line
        (drawingPosition thickness position1 |> toBresenham)
        (drawingPosition thickness position2 |> toBresenham)
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        -- The first element in the list is the starting position, which is assumed to already have been drawn.
        |> List.drop 1
        |> List.map fromBresenham


hitbox : Thickness.Thickness -> DrawingPosition -> DrawingPosition -> Set Pixel
hitbox thickness oldPosition newPosition =
    let
        is45DegreeDraw =
            oldPosition.leftEdge /= newPosition.leftEdge && oldPosition.topEdge /= newPosition.topEdge

        oldPixels =
            pixelsToOccupy thickness oldPosition

        newPixels =
            pixelsToOccupy thickness newPosition
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
