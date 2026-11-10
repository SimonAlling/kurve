port module CloneSimulation exposing (main)

{-| Plays out a round in the clone, given everything that the original game decided on its own: where the Kurves spawned, what the players did, and when the Kurves were holy.

Input (flags) and output (port) are JSON; see compare.mjs.

-}

import Array exposing (Array)
import Color exposing (Color)
import Colors
import Config exposing (Config)
import Game exposing (TickResult(..), prepareRoundFromKnownInitialState, reactToTick)
import Holes exposing (HoleStatus(..), Holiness(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Random
import Round exposing (Round)
import Set
import Types.Angle as Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve, UserInteraction(..))
import Types.PlayerId exposing (PlayerId)
import Types.Tick as Tick exposing (Tick)
import Types.TurningState exposing (TurningState(..))
import World


port outputPort : String -> Cmd msg


main : Program Decode.Value () Never
main =
    Platform.worker
        { init = init
        , update = never
        , subscriptions = always Sub.none
        }


init : Decode.Value -> ( (), Cmd Never )
init flags =
    ( ()
    , case Decode.decodeValue scenarioDecoder flags of
        Ok scenario ->
            playOut scenario |> Encode.encode 0 |> outputPort

        Err error ->
            Encode.object [ ( "error", Encode.string (Decode.errorToString error) ) ] |> Encode.encode 0 |> outputPort
    )


type alias Scenario =
    { kurves : List KurveScenario
    , maxTicks : Int
    , dumpTicks : List Int -- after which ticks (0 = at spawn) to output the occupied pixels
    , whatIfOriginalOrder : Bool -- process Kurves in the same order as the original (Red first) instead of the clone's order (Blue first); see README.md#processing-order
    }


type alias KurveScenario =
    { id : PlayerId
    , x : Float
    , y : Float
    , direction : Float
    , turning : List ( Int, TurningState ) -- (tick, turning state from that tick on), chronologically
    , solidity : Solidity
    }


{-| Whether the Kurve is solid in tick n (0 = at spawn). Non-empty by construction: the last value is stored separately and applies to all later ticks.
-}
type Solidity
    = Solidity (Array Bool) Bool


solidIn : Int -> Solidity -> Bool
solidIn n (Solidity ticks last) =
    Array.get n ticks |> Maybe.withDefault last


solidityDecoder : Decoder Solidity
solidityDecoder =
    Decode.array Decode.bool
        |> Decode.andThen
            (\ticks ->
                case Array.get (Array.length ticks - 1) ticks of
                    Just last ->
                        Decode.succeed (Solidity ticks last)

                    Nothing ->
                        Decode.fail "solidity must be non-empty"
            )


scenarioDecoder : Decoder Scenario
scenarioDecoder =
    Decode.map4 Scenario
        (Decode.field "kurves" (Decode.list kurveScenarioDecoder))
        (Decode.field "maxTicks" Decode.int)
        (Decode.field "dumpTicks" (Decode.list Decode.int))
        (Decode.field "whatIfOriginalOrder" Decode.bool)


kurveScenarioDecoder : Decoder KurveScenario
kurveScenarioDecoder =
    Decode.map6 KurveScenario
        (Decode.field "id" Decode.int)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "direction" Decode.float)
        (Decode.field "turning" (Decode.list (Decode.map2 Tuple.pair (Decode.index 0 Decode.int) (Decode.index 1 turningStateDecoder))))
        (Decode.field "solidity" solidityDecoder)


turningStateDecoder : Decoder TurningState
turningStateDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "left" ->
                        Decode.succeed TurningLeft

                    "right" ->
                        Decode.succeed TurningRight

                    "none" ->
                        Decode.succeed NotTurning

                    _ ->
                        Decode.fail ("Unknown turning state: " ++ s)
            )


config : Config
config =
    Config.default


playOut : Scenario -> Encode.Value
playOut scenario =
    let
        solidities : List ( PlayerId, Solidity )
        solidities =
            List.map (\k -> ( k.id, k.solidity )) scenario.kurves

        initialRound : Round
        initialRound =
            prepareRoundFromKnownInitialState config.world
                { seedAfterSpawn = Random.initialSeed 0
                , spawnedKurves = List.map toKurve scenario.kurves
                }

        dumpIfRequested : Int -> Round -> List Encode.Value -> List Encode.Value
        dumpIfRequested n round dumps =
            if List.member n scenario.dumpTicks then
                Encode.object [ ( "tick", Encode.int n ), ( "canvas", Encode.list Encode.int (runLengthEncode round) ) ] :: dumps

            else
                dumps

        recurse : Tick -> Round -> List Encode.Value -> List Encode.Value -> ( Int, Round, ( List Encode.Value, List Encode.Value ) )
        recurse lastTick round reversedTickRecords reversedDumps =
            let
                tick : Tick
                tick =
                    Tick.succ lastTick

                order : List Kurve -> List Kurve
                order =
                    if scenario.whatIfOriginalOrder then
                        -- reactToTick processes the Kurves from last to first.
                        List.sortBy (.id >> negate)

                    else
                        identity

                roundWithForcedHoles : Round
                roundWithForcedHoles =
                    Round.modifyKurves
                        (\kurves -> { kurves | alive = kurves.alive |> List.map (forceHoleStatus solidities (Tick.toInt tick)) |> order })
                        round
            in
            case reactToTick config tick roundWithForcedHoles |> Tuple.first of
                RoundKeepsGoing nextRound ->
                    let
                        records : ( List Encode.Value, List Encode.Value )
                        records =
                            ( encodeTick nextRound :: reversedTickRecords, dumpIfRequested (Tick.toInt tick) nextRound reversedDumps )
                    in
                    if Tick.toInt tick >= scenario.maxTicks then
                        ( Tick.toInt tick, nextRound, records )

                    else
                        recurse tick nextRound (Tuple.first records) (Tuple.second records)

                RoundEnds _ (Round.Finished finalRound) ->
                    ( Tick.toInt tick, finalRound, ( encodeTick finalRound :: reversedTickRecords, dumpIfRequested (Tick.toInt tick) finalRound reversedDumps ) )

        ( endTick, lastRound, ( reversedRecords, reversedDumpRecords ) ) =
            recurse Tick.genesis initialRound [] (dumpIfRequested 0 initialRound [])
    in
    Encode.object
        [ ( "endTick", Encode.int endTick )
        , ( "ticks", Encode.list identity (List.reverse reversedRecords) )
        , ( "canvas", Encode.list Encode.int (runLengthEncode lastRound) )
        , ( "dumps", Encode.list identity (List.reverse reversedDumpRecords) )
        ]


toKurve : KurveScenario -> Kurve
toKurve k =
    let
        state : Types.Kurve.State
        state =
            { position = ( k.x, k.y )
            , direction = Angle k.direction
            , holeStatus = holeStatusFor k.solidity 1
            }
    in
    { color = colorFor k.id
    , id = k.id
    , controls = ( Set.empty, Set.empty )
    , state = state
    , stateAtSpawn = state
    , reversedInteractions =
        k.turning
            |> List.filterMap (\( n, turningState ) -> Tick.fromInt n |> Maybe.map (\t -> HappenedBefore t turningState))
            |> List.reverse
    }


colorFor : PlayerId -> Color
colorFor id =
    case id of
        0 ->
            Colors.red

        1 ->
            Colors.yellow

        2 ->
            Colors.orange

        3 ->
            Colors.green

        4 ->
            Colors.pink

        _ ->
            Colors.blue


{-| A hole status that makes the Kurve have the given solidity before and in the given tick. See README.md#hole-mapping.
-}
holeStatusFor : Solidity -> Int -> HoleStatus
holeStatusFor solidity tick =
    let
        holinessBefore : Holiness
        holinessBefore =
            if solidIn (tick - 1) solidity then
                Solid

            else
                Holy
    in
    RandomHoles
        { holiness = holinessBefore
        , ticksLeft =
            -- The clone toggles holiness when ticksLeft is 0.
            if solidIn tick solidity == solidIn (tick - 1) solidity then
                1

            else
                0
        , holeSeed = Random.initialSeed 0
        }


forceHoleStatus : List ( PlayerId, Solidity ) -> Int -> Kurve -> Kurve
forceHoleStatus solidities tick kurve =
    case List.filter (Tuple.first >> (==) kurve.id) solidities of
        ( _, solidity ) :: _ ->
            let
                state : Types.Kurve.State
                state =
                    kurve.state
            in
            { kurve | state = { state | holeStatus = holeStatusFor solidity tick } }

        [] ->
            kurve


encodeTick : Round -> Encode.Value
encodeTick round =
    let
        encodeKurve : Bool -> Kurve -> Encode.Value
        encodeKurve alive kurve =
            let
                ( x, y ) =
                    kurve.state.position
            in
            Encode.object
                [ ( "id", Encode.int kurve.id )
                , ( "x", Encode.float x )
                , ( "y", Encode.float y )
                , ( "dir", Encode.float (Angle.toFloat kurve.state.direction) )
                , ( "dead", Encode.bool (not alive) )
                ]
    in
    Encode.list identity (List.map (encodeKurve True) round.kurves.alive ++ List.map (encodeKurve False) round.kurves.dead)


{-| Same format as the original-game harness: row by row, starting with a run of unoccupied pixels.
-}
runLengthEncode : Round -> List Int
runLengthEncode round =
    let
        width : Int
        width =
            config.world.width

        height : Int
        height =
            config.world.height

        go : Int -> Bool -> Int -> List Int -> List Int
        go i current run reversedRuns =
            if i >= width * height then
                List.reverse (run :: reversedRuns)

            else
                let
                    occupied : Bool
                    occupied =
                        World.isOccupied round.occupiedPixels ( modBy width i, i // width )
                in
                if occupied == current then
                    go (i + 1) current (run + 1) reversedRuns

                else
                    go (i + 1) occupied 1 (run :: reversedRuns)
    in
    go 0 False 0 []
