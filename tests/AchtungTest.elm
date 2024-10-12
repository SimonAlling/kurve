module AchtungTest exposing (tests)

import Color
import Config
import Expect
import Game exposing (MidRoundState, MidRoundStateVariant(..), TickResult(..), prepareRoundFromKnownInitialState, reactToTick)
import Random
import Round exposing (Round, RoundInitialState)
import Set
import String
import Test exposing (Test, describe, test)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Tick as Tick exposing (Tick)
import World


tests : Test
tests =
    describe "Achtung, die Kurve!"
        [ test
            "Kurves move forward by default when game is active"
            (\_ ->
                let
                    currentKurve : Kurve
                    currentKurve =
                        { color = Color.white
                        , id = 5
                        , controls = ( Set.empty, Set.empty )
                        , state =
                            { position = ( 100, 100 )
                            , direction = Angle 0
                            , holeStatus = Unholy 60
                            }
                        , stateAtSpawn =
                            { position = ( 100, 100 )
                            , direction = Angle 0
                            , holeStatus = Unholy 60
                            }
                        , reversedInteractions = []
                        }

                    currentRound : Round
                    currentRound =
                        prepareRoundFromKnownInitialState
                            { seedAfterSpawn = Random.initialSeed 0
                            , spawnedKurves = [ currentKurve ]
                            }

                    tickResult : TickResult
                    tickResult =
                        reactToTick Config.default (Tick.succ Tick.genesis) ( Live, currentRound ) |> Tuple.first
                in
                case tickResult of
                    RoundKeepsGoing _ ( _, round ) ->
                        case round.kurves.alive of
                            kurve :: [] ->
                                Expect.equal kurve.state.position
                                    ( 101, 100 )

                            _ ->
                                Expect.fail "Expected exactly one alive Kurve"

                    RoundEnds _ ->
                        Expect.fail "Expected round not to end"
            )
        , test
            "A Kurve that crashes into the wall dies"
            (\_ ->
                let
                    currentKurve : Kurve
                    currentKurve =
                        { color = Color.white
                        , id = 5
                        , controls = ( Set.empty, Set.empty )
                        , state =
                            { position = ( 2.5, 100 )
                            , direction = Angle pi
                            , holeStatus = Unholy 60
                            }
                        , stateAtSpawn =
                            { position = ( 100, 100 )
                            , direction = Angle 0
                            , holeStatus = Unholy 60
                            }
                        , reversedInteractions = []
                        }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ currentKurve ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        { tickThatShouldEndIt = tickNumber 2
                        , howItShouldEnd =
                            \round ->
                                case ( round.kurves.alive, round.kurves.dead ) of
                                    ( [], kurve :: [] ) ->
                                        Expect.equal kurve.state.position
                                            ( 0.5, 100 )

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and no alive ones"
                        }
            )
        , crashTimingTests
        ]


{-| TODO: comment
-}
crashTimingTests : Test
crashTimingTests =
    describe "Crash timing"
        [ crashingIntoWallTest
        , crashingIntoKurveTests
        ]


crashingIntoWallTest : Test
crashingIntoWallTest =
    test "The exact timing of a crash into the wall is predictable for the player"
        (\_ ->
            let
                currentKurve : Kurve
                currentKurve =
                    { color = Color.white
                    , id = 5
                    , controls = ( Set.empty, Set.empty )
                    , state =
                        { position = ( 100, 3.5 )
                        , direction = Angle 0.01
                        , holeStatus = Unholy 60000
                        }
                    , stateAtSpawn =
                        { position = ( 0, 0 )
                        , direction = Angle 0
                        , holeStatus = Unholy 0
                        }
                    , reversedInteractions = []
                    }

                initialState : RoundInitialState
                initialState =
                    { seedAfterSpawn = Random.initialSeed 0
                    , spawnedKurves = [ currentKurve ]
                    }
            in
            initialState
                |> expectRoundOutcome
                    { tickThatShouldEndIt = tickNumber 251
                    , howItShouldEnd =
                        \round ->
                            case ( round.kurves.alive, round.kurves.dead ) of
                                ( [], [ kurve ] ) ->
                                    let
                                        theDrawingPositionItNeverMadeItTo : World.DrawingPosition
                                        theDrawingPositionItNeverMadeItTo =
                                            World.drawingPosition kurve.state.position
                                    in
                                    Expect.equal theDrawingPositionItNeverMadeItTo
                                        { leftEdge = 349, topEdge = -1 }

                                _ ->
                                    Expect.fail "Expected exactly one dead Kurve and no alive ones"
                    }
        )


crashingIntoKurveTests : Test
crashingIntoKurveTests =
    describe "The exact timing of a crash into a Kurve is predictable for the player"
        (List.range 0 9
            |> List.map
                (\decimal ->
                    let
                        y_red : Float
                        y_red =
                            100 + toFloat decimal / 10
                    in
                    test
                        ("When Red's vertical position is " ++ String.fromFloat y_red)
                        (\_ ->
                            let
                                red : Kurve
                                red =
                                    { color = Color.red
                                    , id = 0
                                    , controls = ( Set.empty, Set.empty )
                                    , state =
                                        { position = ( 150, y_red )
                                        , direction = Angle 0
                                        , holeStatus = Unholy 60000
                                        }
                                    , stateAtSpawn =
                                        { position = ( 0, 0 )
                                        , direction = Angle 0
                                        , holeStatus = Unholy 0
                                        }
                                    , reversedInteractions = []
                                    }

                                green : Kurve
                                green =
                                    { color = Color.green
                                    , id = 3
                                    , controls = ( Set.empty, Set.empty )
                                    , state =
                                        { position = ( 100, 107.5 )
                                        , direction = Angle 0.02
                                        , holeStatus = Unholy 60000
                                        }
                                    , stateAtSpawn =
                                        { position = ( 0, 0 )
                                        , direction = Angle 0
                                        , holeStatus = Unholy 0
                                        }
                                    , reversedInteractions = []
                                    }

                                initialState : RoundInitialState
                                initialState =
                                    { seedAfterSpawn = Random.initialSeed 0
                                    , spawnedKurves = [ red, green ]
                                    }
                            in
                            initialState
                                |> expectRoundOutcome
                                    { tickThatShouldEndIt = tickNumber 226
                                    , howItShouldEnd =
                                        \round ->
                                            case ( round.kurves.alive, round.kurves.dead ) of
                                                ( [ _ ], [ deadKurve ] ) ->
                                                    let
                                                        theDrawingPositionItNeverMadeItTo : World.DrawingPosition
                                                        theDrawingPositionItNeverMadeItTo =
                                                            World.drawingPosition deadKurve.state.position
                                                    in
                                                    Expect.all
                                                        [ \() ->
                                                            theDrawingPositionItNeverMadeItTo
                                                                |> Expect.equal { leftEdge = 324, topEdge = 101 }
                                                        , \() ->
                                                            deadKurve.color
                                                                |> Expect.equal Color.green
                                                        ]
                                                        ()

                                                _ ->
                                                    Expect.fail "Expected exactly one dead Kurve and one alive one"
                                    }
                        )
                )
        )


{-| A description of when and how a round should end.
-}
type alias RoundOutcome =
    { tickThatShouldEndIt : Tick
    , howItShouldEnd : Round -> Expect.Expectation
    }


expectRoundOutcome : RoundOutcome -> RoundInitialState -> Expect.Expectation
expectRoundOutcome { tickThatShouldEndIt, howItShouldEnd } initialState =
    let
        recurse : Tick -> MidRoundState -> Expect.Expectation
        recurse tick midRoundState =
            let
                tickResult : TickResult
                tickResult =
                    reactToTick Config.default (Tick.succ tick) midRoundState |> Tuple.first
            in
            case tickResult of
                RoundKeepsGoing nextTick nextMidRoundState ->
                    if nextTick == tickThatShouldEndIt then
                        Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it did not."

                    else
                        recurse nextTick nextMidRoundState

                RoundEnds actualRoundResult ->
                    let
                        actualEndTick : Tick
                        actualEndTick =
                            Tick.succ tick
                    in
                    if actualEndTick == tickThatShouldEndIt then
                        howItShouldEnd actualRoundResult

                    else
                        Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it ended on tick " ++ showTick actualEndTick ++ "."

        round : Round
        round =
            prepareRoundFromKnownInitialState initialState
    in
    recurse Tick.genesis ( Live, round )


showTick : Tick -> String
showTick =
    Tick.toInt >> String.fromInt


tickNumber : Int -> Tick
tickNumber n =
    case Tick.fromInt n of
        Nothing ->
            Debug.todo <| "Tick cannot be negative (was " ++ String.fromInt n ++ ")."

        Just tick ->
            tick
