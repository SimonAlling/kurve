module Movie exposing (..)

import Bitwise
import Bytes
import Bytes.Decode as Decode exposing (Decoder)
import Bytes.Encode as Encode exposing (Encoder)
import Holes exposing (Holiness(..))
import Types.Kurve exposing (Kurve)
import Types.PlayerId exposing (PlayerId)
import Types.Tick as Tick exposing (Tick)
import World exposing (DrawingPosition)


type alias Movie =
    { movesPerTick : Int
    , kurves : List MovieKurve
    }


type alias MovieKurve =
    { playerId : PlayerId
    , initialDrawingPosition : DrawingPosition
    , initialHoliness : Holiness

    -- Each listed tick the holiness flips. Note that the smallest possible tick is 1 (not 0).
    , holinessChanges : List Tick

    -- Note: A Kurve never moves in one direction and then directly in the opposite direction.
    -- That is instead used to denote that the kurve didn’t move at all.
    -- `[ N, S ]` means north, then no movement.
    -- `[ N, S, S ]` means north, then no movement twice.
    -- `[ N, S, N ]` means north, then no movement, then north.
    , moves : List Direction
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


fromKurves : List Kurve -> Movie
fromKurves kurves =
    let
        movesPerTick =
            getMovesPerTick kurves
    in
    { movesPerTick = movesPerTick
    , kurves = List.map (toMovieKurve movesPerTick) kurves
    }


getMovesPerTick : List Kurve -> Int
getMovesPerTick kurves =
    kurves
        |> List.concatMap (.reversedDrawingPositionsPerTick >> List.map List.length)
        |> List.maximum
        |> Maybe.withDefault 0


toMovieKurve : Int -> Kurve -> MovieKurve
toMovieKurve movesPerTick kurve =
    let
        initialDrawingPosition =
            World.drawingPosition kurve.stateAtSpawn.position
    in
    { playerId = kurve.id
    , initialDrawingPosition = initialDrawingPosition
    , initialHoliness = Holes.getHoliness kurve.stateAtSpawn.holeStatus
    , holinessChanges = List.reverse kurve.reversedHolinessChanges
    , moves =
        kurve.reversedDrawingPositionsPerTick
            |> toMoves movesPerTick initialDrawingPosition
            |> List.reverse
    }


toMoves : Int -> DrawingPosition -> List (List DrawingPosition) -> List Direction
toMoves movesPerTick initialDrawingPosition reversedDrawingPositions =
    let
        ( _, _, directions ) =
            reversedDrawingPositions
                |> List.foldr
                    (\tickDrawingPositions outerAcc ->
                        let
                            ( newLastDrawingPosition, newLastDirection, newAcc ) =
                                tickDrawingPositions
                                    |> List.foldr
                                        (\drawingPosition ( lastDrawingPosition, lastDirection, acc ) ->
                                            let
                                                direction =
                                                    case getDirection lastDrawingPosition drawingPosition of
                                                        Just direction_ ->
                                                            direction_

                                                        Nothing ->
                                                            opposite lastDirection
                                            in
                                            ( drawingPosition
                                            , direction
                                            , direction :: acc
                                            )
                                        )
                                        outerAcc

                            lengthDiff =
                                movesPerTick - List.length tickDrawingPositions

                            paddedAcc =
                                if lengthDiff > 0 then
                                    List.repeat lengthDiff (opposite newLastDirection) ++ newAcc

                                else
                                    newAcc
                        in
                        ( newLastDrawingPosition, newLastDirection, paddedAcc )
                    )
                    ( initialDrawingPosition
                    , N
                    , []
                    )
    in
    directions


getDirection : DrawingPosition -> DrawingPosition -> Maybe Direction
getDirection previousDrawingPosition drawingPosition =
    case ( compare drawingPosition.x previousDrawingPosition.x, compare drawingPosition.y previousDrawingPosition.y ) of
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


opposite : Direction -> Direction
opposite direction =
    case direction of
        N ->
            S

        NE ->
            SW

        E ->
            W

        SE ->
            NW

        S ->
            N

        SW ->
            NE

        W ->
            E

        NW ->
            SE


endianness : Bytes.Endianness
endianness =
    Bytes.BE


latestVersion : Int
latestVersion =
    0


encoder : Movie -> Encoder
encoder movie =
    Encode.sequence
        [ Encode.unsignedInt8 latestVersion
        , Encode.unsignedInt8 movie.movesPerTick
        , kurvesEncoder movie.kurves
        ]


decoder : Decoder Movie
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


v0Decoder : Decoder Movie
v0Decoder =
    Decode.map2 Movie
        Decode.unsignedInt8
        kurvesDecoder


kurvesEncoder : List MovieKurve -> Encoder
kurvesEncoder kurves =
    Encode.sequence
        [ Encode.unsignedInt8 (List.length kurves)
        , Encode.sequence (List.map kurveEncoder kurves)
        ]


kurvesDecoder : Decoder (List MovieKurve)
kurvesDecoder =
    Decode.unsignedInt8
        |> Decode.andThen
            (\length ->
                list length kurveDecoder
            )


kurveEncoder : MovieKurve -> Encoder
kurveEncoder kurve =
    Encode.sequence
        [ Encode.unsignedInt8 kurve.playerId
        , drawingPositionEncoder kurve.initialDrawingPosition
        , holinessEncoder kurve.initialHoliness
        , holinessChangesEncoder kurve.holinessChanges
        , movesEncoder kurve.moves
        ]


kurveDecoder : Decoder MovieKurve
kurveDecoder =
    Decode.map5 MovieKurve
        Decode.unsignedInt8
        drawingPositionDecoder
        holinessDecoder
        holinessChangesDecoder
        movesDecoder


drawingPositionEncoder : DrawingPosition -> Encoder
drawingPositionEncoder { x, y } =
    Encode.sequence
        [ Encode.unsignedInt16 endianness x
        , Encode.unsignedInt16 endianness y
        ]


drawingPositionDecoder : Decoder DrawingPosition
drawingPositionDecoder =
    Decode.map2 DrawingPosition
        (Decode.unsignedInt16 endianness)
        (Decode.unsignedInt16 endianness)


holinessEncoder : Holiness -> Encoder
holinessEncoder holiness =
    Encode.unsignedInt8
        (case holiness of
            Holy ->
                0

            Solid ->
                1
        )


holinessDecoder : Decoder Holiness
holinessDecoder =
    Decode.unsignedInt8
        |> Decode.andThen
            (\int ->
                case int of
                    0 ->
                        Decode.succeed Holy

                    1 ->
                        Decode.succeed Solid

                    _ ->
                        Decode.fail
            )


holinessChangesEncoder : List Tick -> Encoder
holinessChangesEncoder ticks =
    Encode.sequence
        [ Encode.unsignedInt32 endianness (List.length ticks)
        , Encode.sequence (List.map tickEncoder ticks)
        ]


holinessChangesDecoder : Decoder (List Tick)
holinessChangesDecoder =
    Decode.unsignedInt32 endianness
        |> Decode.andThen (\length -> list length tickDecoder)


tickEncoder : Tick -> Encoder
tickEncoder =
    Tick.toInt >> Encode.unsignedInt32 endianness


tickDecoder : Decoder Tick
tickDecoder =
    Decode.unsignedInt32 endianness
        |> Decode.andThen
            (\int ->
                case Tick.fromInt int of
                    Just tick ->
                        Decode.succeed tick

                    Nothing ->
                        Decode.fail
            )


movesEncoder : List Direction -> Encoder
movesEncoder moves =
    Encode.sequence
        [ Encode.unsignedInt32 endianness (List.length moves)
        , Encode.sequence (movesEncoderHelper [] moves)
        ]


movesDecoder : Decoder (List Direction)
movesDecoder =
    Decode.unsignedInt32 endianness
        |> Decode.andThen
            (\numMoves ->
                Decode.loop ( numMoves, [] ) movesDecoderHelper
            )


movesEncoderHelper : List Encoder -> List Direction -> List Encoder
movesEncoderHelper acc moves =
    case moves of
        [] ->
            List.reverse acc

        _ ->
            let
                left =
                    List.take 8 moves

                rest =
                    List.drop 8 moves

                lengthDiff =
                    8 - List.length left

                paddedLeft =
                    if lengthDiff > 0 then
                        left ++ List.repeat lengthDiff N

                    else
                        left
            in
            movesEncoderHelper (moveEncoder paddedLeft :: acc) rest


moveEncoder : List Direction -> Encoder
moveEncoder piece8 =
    let
        combined =
            piece8
                |> List.foldl
                    (\direction acc ->
                        (acc |> Bitwise.shiftLeftBy 3) + directionToInt direction
                    )
                    0
    in
    Encode.sequence
        [ Encode.unsignedInt8 (combined |> Bitwise.shiftRightZfBy 16)
        , Encode.unsignedInt8 (combined |> Bitwise.shiftRightZfBy 8 |> Bitwise.and b11111111)
        , Encode.unsignedInt8 (Bitwise.and combined b11111111)
        ]


movesDecoderHelper : ( Int, List Direction ) -> Decoder (Decode.Step ( Int, List Direction ) (List Direction))
movesDecoderHelper ( numMoves, acc ) =
    Decode.map3
        (\a b c ->
            let
                movesLeft =
                    numMoves - 8

                toDrop =
                    max 0 -movesLeft

                combinedFull =
                    (a |> Bitwise.shiftLeftBy 16)
                        + (b |> Bitwise.shiftLeftBy 8)
                        + c

                combined =
                    combinedFull
                        |> Bitwise.shiftRightZfBy (3 * toDrop)

                moves =
                    List.range 0 (7 - toDrop)
                        |> List.foldr
                            (\i newAcc ->
                                let
                                    direction =
                                        combined
                                            |> Bitwise.shiftRightZfBy (3 * i)
                                            |> Bitwise.and b111
                                            |> intToDirection
                                in
                                direction :: newAcc
                            )
                            acc
            in
            if movesLeft > 0 then
                Decode.Loop ( movesLeft, moves )

            else
                Decode.Done (List.reverse moves)
        )
        Decode.unsignedInt8
        Decode.unsignedInt8
        Decode.unsignedInt8


b111 : Int
b111 =
    7


b11111111 : Int
b11111111 =
    255


directionToInt : Direction -> Int
directionToInt direction =
    case direction of
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


intToDirection : Int -> Direction
intToDirection int =
    case int of
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


list : Int -> Decoder a -> Decoder (List a)
list len itemDecoder =
    Decode.loop ( len, [] ) (listStep itemDecoder)


listStep : Decoder a -> ( Int, List a ) -> Decoder (Decode.Step ( Int, List a ) (List a))
listStep itemDecoder ( n, xs ) =
    if n <= 0 then
        Decode.succeed (Decode.Done (List.reverse xs))

    else
        Decode.map (\x -> Decode.Loop ( n - 1, x :: xs )) itemDecoder
