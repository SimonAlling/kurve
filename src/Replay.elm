module Replay exposing (..)

import Bitwise
import Bytes
import Bytes.Decode as Decode exposing (Decoder)
import Bytes.Encode as Encode exposing (Encoder)
import Holes exposing (Holiness(..))
import Types.Kurve exposing (Kurve)
import Types.PlayerId exposing (PlayerId)
import World exposing (DrawingPosition)


type alias Replay =
    { movesPerTick : Int
    , kurves : List ReplayKurve
    }


type alias ReplayKurve =
    { playerId : PlayerId
    , initialDrawingPosition : DrawingPosition
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
    { movesPerTick = movesPerTick
    , kurves = List.map (toReplayKurve movesPerTick) kurves
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
    { playerId = kurve.id
    , initialDrawingPosition = initialDrawingPosition
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


latestVersion : Int
latestVersion =
    0


endianness : Bytes.Endianness
endianness =
    Bytes.BE


encoder : Replay -> Encoder
encoder replay =
    Encode.sequence
        [ Encode.unsignedInt8 latestVersion
        , Encode.unsignedInt8 replay.movesPerTick
        , Encode.unsignedInt8 (List.length replay.kurves)
        , Encode.sequence (replay.kurves |> List.map (.playerId >> Encode.unsignedInt8))
        , Encode.sequence (replay.kurves |> List.map (.initialDrawingPosition >> drawingPositionEncoder))
        , Encode.sequence (replay.kurves |> List.map (.moves >> movesEncoder))
        ]


drawingPositionEncoder : DrawingPosition -> Encoder
drawingPositionEncoder { x, y } =
    Encode.sequence
        [ Encode.unsignedInt16 endianness x
        , Encode.unsignedInt16 endianness y
        ]


movesEncoder : List Move -> Encoder
movesEncoder moves =
    Encode.sequence
        [ Encode.unsignedInt32 endianness (List.length moves)
        , Encode.sequence (List.map moveEncoder moves)
        ]


moveEncoder : Move -> Encoder
moveEncoder move =
    Encode.unsignedInt8 (moveToUint8 move)


moveToUint8 : Move -> Int
moveToUint8 move =
    let
        repetitions =
            move.repetitions

        holiness =
            case move.holiness of
                Holy ->
                    1

                Solid ->
                    0

        direction =
            case move.direction of
                N ->
                    0

                NE ->
                    1

                E ->
                    2

                SE ->
                    3

                S ->
                    4

                SW ->
                    5

                W ->
                    6

                NW ->
                    7
    in
    (repetitions |> Bitwise.shiftLeftBy 4)
        + (holiness |> Bitwise.shiftLeftBy 3)
        + direction


decoder : Decoder Replay
decoder =
    Decode.unsignedInt8
        |> Decode.andThen
            (\version ->
                case version of
                    0 ->
                        v0Decoder

                    _ ->
                        Decode.fail
            )


v0Decoder : Decoder Replay
v0Decoder =
    Decode.map2 Replay
        Decode.unsignedInt8
        kurvesDecoder


kurvesDecoder : Decoder (List ReplayKurve)
kurvesDecoder =
    Decode.unsignedInt8
        |> Decode.andThen
            (\numKurves ->
                Decode.map3 (List.map3 ReplayKurve)
                    (list numKurves Decode.unsignedInt8)
                    (list numKurves drawingPositionDecoder)
                    (list numKurves movesDecoder)
            )


list : Int -> Decoder a -> Decoder (List a)
list len itemDecoder =
    Decode.loop ( len, [] ) (listStep itemDecoder)


listStep : Decoder a -> ( Int, List a ) -> Decoder (Decode.Step ( Int, List a ) (List a))
listStep itemDecoder ( n, xs ) =
    if n <= 0 then
        Decode.succeed (Decode.Done (List.reverse xs))

    else
        Decode.map (\x -> Decode.Loop ( n - 1, x :: xs )) itemDecoder


drawingPositionDecoder : Decoder DrawingPosition
drawingPositionDecoder =
    Decode.map2 DrawingPosition
        (Decode.unsignedInt16 endianness)
        (Decode.unsignedInt16 endianness)


movesDecoder : Decoder (List Move)
movesDecoder =
    Decode.unsignedInt32 endianness
        |> Decode.andThen
            (\numMoves ->
                list numMoves moveDecoder
            )


moveDecoder : Decoder Move
moveDecoder =
    Decode.unsignedInt8 |> Decode.map uint8ToMove


uint8ToMove : Int -> Move
uint8ToMove int =
    let
        direction =
            case Bitwise.and int 7 of
                0 ->
                    N

                1 ->
                    NE

                2 ->
                    E

                3 ->
                    SE

                4 ->
                    S

                5 ->
                    SW

                6 ->
                    W

                _ ->
                    NW
    in
    { repetitions = int |> Bitwise.shiftRightZfBy 4
    , holiness =
        if Bitwise.and int 8 == 1 then
            Solid

        else
            Holy
    , direction = direction
    }
