module Replay exposing (..)

import Holes exposing (Holiness(..))
import Types.Kurve exposing (Kurve)
import Types.PlayerId exposing (PlayerId)
import World exposing (DrawingPosition)


type alias Replay =
    { kurves : List ReplayKurve
    , movesPerTick : Int
    }


type alias ReplayKurve =
    { initialDrawingPosition : DrawingPosition
    , playerId : PlayerId
    , moves : List Move
    }


maxRepetitions : Int
maxRepetitions =
    15


type alias Move =
    { repetitions : Int -- 0–15. 0 means “no movement” and the direction is ignored.
    , direction : Direction
    , holiness : Holiness
    }


type Direction
    = N
    | NE
    | E
    | SE
    | S
    | SW
    | W
    | NW


fromKurves : List Kurve -> Replay
fromKurves kurves =
    let
        movesPerTick =
            getMovesPerTick kurves
    in
    { kurves = List.map (toReplayKurve movesPerTick) kurves
    , movesPerTick = movesPerTick
    }


getMovesPerTick : List Kurve -> Int
getMovesPerTick kurves =
    kurves
        |> List.concatMap (.reversedDrawingPositionsPerTick >> List.map List.length)
        |> List.maximum
        |> Maybe.withDefault 0


toReplayKurve : Int -> Kurve -> ReplayKurve
toReplayKurve movesPerTick kurve =
    let
        initialDrawingPosition =
            World.drawingPosition kurve.stateAtSpawn.position
    in
    { initialDrawingPosition = initialDrawingPosition
    , playerId = kurve.id
    , moves =
        kurve.reversedDrawingPositionsPerTick
            |> List.concatMap (pad movesPerTick)
            |> toMoves initialDrawingPosition
            |> optimizeRepetitions
            |> List.reverse
    }


pad : Int -> List ( DrawingPosition, Holiness ) -> List ( DrawingPosition, Holiness )
pad length reversedList =
    let
        actualLength =
            List.length reversedList
    in
    if actualLength < length then
        let
            padding =
                List.head reversedList |> Maybe.withDefault ( { x = 0, y = 0 }, Holy )
        in
        reversedList ++ List.repeat (length - actualLength) padding

    else
        reversedList


toMoves : DrawingPosition -> List ( DrawingPosition, Holiness ) -> List Move
toMoves initialDrawingPosition reversedDrawingPositions =
    reversedDrawingPositions
        |> List.foldr
            (\( drawingPosition, holiness ) ( lastDrawingPosition, acc ) ->
                let
                    move : Move
                    move =
                        case getDirection lastDrawingPosition drawingPosition of
                            Just direction ->
                                { repetitions = 1
                                , direction = direction
                                , holiness = holiness
                                }

                            Nothing ->
                                { repetitions = 0
                                , direction = N
                                , holiness = holiness
                                }
                in
                ( drawingPosition
                , move :: acc
                )
            )
            ( initialDrawingPosition
            , []
            )
        |> Tuple.second


getDirection : DrawingPosition -> DrawingPosition -> Maybe Direction
getDirection previousDrawingPosition drawingPosition =
    case ( compare previousDrawingPosition.x drawingPosition.x, compare previousDrawingPosition.y drawingPosition.y ) of
        ( EQ, LT ) ->
            Just N

        ( GT, LT ) ->
            Just NE

        ( GT, EQ ) ->
            Just E

        ( GT, GT ) ->
            Just SE

        ( EQ, GT ) ->
            Just S

        ( LT, GT ) ->
            Just SW

        ( LT, EQ ) ->
            Just W

        ( LT, LT ) ->
            Just NW

        ( EQ, EQ ) ->
            Nothing


optimizeRepetitions : List Move -> List Move
optimizeRepetitions reversedMoves =
    case reversedMoves of
        [] ->
            []

        last :: rest ->
            let
                ( finalMove, finalAcc ) =
                    rest
                        |> List.foldr
                            (\move ( previousMove, acc ) ->
                                let
                                    repetitions =
                                        previousMove.repetitions + move.repetitions
                                in
                                if
                                    (repetitions < maxRepetitions)
                                        && (previousMove.repetitions > 0)
                                        && (move.repetitions > 0)
                                        && (previousMove.direction == move.direction)
                                        && (previousMove.holiness == move.holiness)
                                then
                                    ( { move | repetitions = repetitions }, acc )

                                else
                                    ( move, previousMove :: acc )
                            )
                            ( last, [] )
            in
            finalMove :: finalAcc
