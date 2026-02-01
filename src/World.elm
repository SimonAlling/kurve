module World exposing
    ( DrawingPosition
    , Pixel
    , Position
    , desiredDrawingPositions
    , distanceBetween
    , drawingPosition
    , hitbox
    , occupyDrawingPosition
    )

import List.Cartesian
import RasterShapes
import Set exposing (Set)
import Thickness exposing (theThickness)
import Types.Distance exposing (Distance(..))
import Util exposing (sign)


type alias Position =
    ( Float, Float )


{-| The upper left corner of the drawn square.
-}
type alias DrawingPosition =
    { x : Int, y : Int }


type alias Pixel =
    ( Int, Int )


occupyDrawingPosition : DrawingPosition -> Set Pixel -> Set Pixel
occupyDrawingPosition drawingPos occupiedPixels =
    Set.union (pixelsToOccupy drawingPos) occupiedPixels


distanceBetween : Position -> Position -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


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
desiredDrawingPositions startingPoint desiredEndPoint =
    let
        ( x1, y1 ) =
            startingPoint

        ( x2, y2 ) =
            desiredEndPoint

        drawingPositionStart : DrawingPosition
        drawingPositionStart =
            drawingPosition startingPoint

        drawingPositionEnd : DrawingPosition
        drawingPositionEnd =
            drawingPosition desiredEndPoint

        startIsSameAsEnd : Bool
        startIsSameAsEnd =
            drawingPositionStart == drawingPositionEnd

        theReasonIsTruncation : Bool
        theReasonIsTruncation =
            sign x1 /= sign x2 || sign y1 /= sign y2
    in
    RasterShapes.line
        drawingPositionStart
        drawingPositionEnd
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        -- The first element in the list is the starting position, which is assumed to already have been drawn.
        |> (if startIsSameAsEnd && theReasonIsTruncation then
                -- If the starting position and the end position are equal _because_ the Kurve crossed the top or left edge of the canvas, then we want to draw at the same position again.
                identity

            else
                List.drop 1
           )


hitbox : DrawingPosition -> DrawingPosition -> Set Pixel
hitbox oldPosition newPosition =
    let
        newPixels : Set Pixel
        newPixels =
            pixelsToOccupy newPosition

        pointInFrontOfKurve : ( Float, Float )
        pointInFrontOfKurve =
            computePointInFront oldPosition newPosition
    in
    newPixels |> Set.filter (isCloseTo pointInFrontOfKurve)


{-| Computes a point in front of the Kurve from which the hitbox can be computed.
-}
computePointInFront : DrawingPosition -> DrawingPosition -> ( Float, Float )
computePointInFront oldPosition newPosition =
    let
        -- To compute the point in front of the Kurve, we need to start from the center of its head.
        centerPixel : Pixel
        centerPixel =
            ( oldPosition.x + 1, oldPosition.y + 1 )

        ( cx, cy ) =
            Tuple.mapBoth toFloat toFloat centerPixel

        -- We also need the direction and length of this drawing-position step.
        movementVector : ( Float, Float )
        movementVector =
            ( newPosition.x - oldPosition.x |> toFloat
            , newPosition.y - oldPosition.y |> toFloat
            )

        ( dx, dy ) =
            -- This gives us a vector that will take us from the center pixel to the point in front of the Kurve.
            scaleBy 2.5 movementVector
    in
    ( cx + dx, cy + dy )


{-| Whether the given pixel is close enough to the point in front of the Kurve to be part of the hitbox.
-}
isCloseTo : ( Float, Float ) -> Pixel -> Bool
isCloseTo ( x_front, y_front ) ( x_candidate, y_candidate ) =
    let
        squaredDistanceBetweenPoints : Float
        squaredDistanceBetweenPoints =
            (x_front - toFloat x_candidate) ^ 2 + (y_front - toFloat y_candidate) ^ 2
    in
    squaredDistanceBetweenPoints <= maxSquaredDistance


{-| Must be at least 5/4 (inclusive) and at most (3/2)² = 9/4 (exclusive); see the PR that added this comment.
-}
maxSquaredDistance : Float
maxSquaredDistance =
    2


scaleBy : Float -> ( Float, Float ) -> ( Float, Float )
scaleBy k ( x, y ) =
    ( k * x, k * y )
