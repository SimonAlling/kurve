module AchtungTest exposing (tests)

import Color
import Config exposing (Config, KurveConfig)
import Expect
import Game exposing (MidRoundState, MidRoundStateVariant(..), TickResult(..), prepareRoundFromKnownInitialState, reactToTick)
import Random
import Round exposing (Round, RoundInitialState)
import Set
import String
import Test exposing (Test, describe, test)
import Types.Angle exposing (Angle(..))
import Types.Kurve as Kurve exposing (HoleStatus(..), Kurve, UserInteraction(..))
import Types.PlayerId exposing (PlayerId)
import Types.Speed as Speed exposing (Speed(..))
import Types.Tick as Tick exposing (Tick)
import Types.TurningState exposing (TurningState(..))
import World


tests : Test
tests =
    Test.concat
        [ basicTests
        , crashingIntoKurveTests
        , crashingIntoWallTests
        , crashTimingTests
        , cuttingCornersTests
        , speedTests
        ]


basicTests : Test
basicTests =
    describe "Basic tests"
        [ test "Kurves move forward by default when game is active" <|
            \_ ->
                let
                    currentKurve : Kurve
                    currentKurve =
                        makeZombieKurve
                            { color = Color.white
                            , id = 5
                            , state =
                                { position = ( 100, 100 )
                                , direction = Angle 0
                                , holeStatus = Unholy 60
                                }
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
        , test "A Kurve that crashes into the wall dies" <|
            \_ ->
                let
                    currentKurve : Kurve
                    currentKurve =
                        makeZombieKurve
                            { color = Color.white
                            , id = 5
                            , state =
                                { position = ( 2.5, 100 )
                                , direction = Angle pi
                                , holeStatus = Unholy 60
                                }
                            }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ currentKurve ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
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
        , test "Around the world, touching each wall" <|
            \_ ->
                let
                    greenZombie : Kurve
                    greenZombie =
                        makeZombieKurve
                            { color = Color.green
                            , id = 3
                            , state =
                                { position = ( 4.5, 1.5 )
                                , direction = Angle 0
                                , holeStatus = Unholy 60000
                                }
                            }

                    green : Kurve
                    green =
                        { greenZombie
                            | reversedInteractions =
                                makeUserInteractions
                                    -- Intended to make the Kurve touch each of the four walls on its way around the world.
                                    [ ( 526, TurningRight )
                                    , ( 45, NotTurning )
                                    , ( 420, TurningRight )
                                    , ( 45, NotTurning )
                                    , ( 491, TurningRight )
                                    , ( 44, NotTurning )
                                    ]
                        }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ green ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 2011
                        , howItShouldEnd =
                            \round ->
                                case ( round.kurves.alive, round.kurves.dead ) of
                                    ( [], deadKurve :: [] ) ->
                                        let
                                            theDrawingPositionItNeverMadeItTo : World.DrawingPosition
                                            theDrawingPositionItNeverMadeItTo =
                                                World.drawingPosition deadKurve.state.position
                                        in
                                        theDrawingPositionItNeverMadeItTo
                                            |> Expect.equal { leftEdge = 0, topEdge = -1 }

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and no alive ones"
                        }
        ]


crashingIntoKurveTests : Test
crashingIntoKurveTests =
    describe "Crashing into a Kurve"
        [ test "Hitting a Kurve's tail end is a crash" <|
            \_ ->
                let
                    red : Kurve
                    red =
                        makeZombieKurve
                            { color = Color.red
                            , id = 0
                            , state =
                                { position = ( 100.5, 100.5 )
                                , direction = Angle 0
                                , holeStatus = Unholy 60000
                                }
                            }

                    green : Kurve
                    green =
                        makeZombieKurve
                            { color = Color.green
                            , id = 3
                            , state =
                                { position = ( 98.5, 110.5 )
                                , direction = Angle (pi / 2)
                                , holeStatus = Unholy 60000
                                }
                            }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ red, green ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 8
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
                                                    |> Expect.equal { leftEdge = 97, topEdge = 101 }
                                            , \() ->
                                                deadKurve.color
                                                    |> Expect.equal Color.green
                                            ]
                                            ()

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and one alive one"
                        }
        , test "Hitting a Kurve's tail end at a 45-degree angle is a crash" <|
            \_ ->
                let
                    red : Kurve
                    red =
                        makeZombieKurve
                            { color = Color.red
                            , id = 0
                            , state =
                                { position = ( 60.5, 60.5 )
                                , direction = Angle (-pi / 4)
                                , holeStatus = Unholy 60000
                                }
                            }

                    green : Kurve
                    green =
                        makeZombieKurve
                            { color = Color.green
                            , id = 3
                            , state =
                                { position = ( 30.5, 30.5 )
                                , direction = Angle (-pi / 4)
                                , holeStatus = Unholy 60000
                                }
                            }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ red, green ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 39
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
                                                    |> Expect.equal { leftEdge = 57, topEdge = 57 }
                                            , \() ->
                                                deadKurve.color
                                                    |> Expect.equal Color.green
                                            ]
                                            ()

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and one alive one"
                        }
        ]


crashingIntoWallTests : Test
crashingIntoWallTests =
    describe "Crashing into a wall"
        (let
            tickThatShouldEndIt : Tick
            tickThatShouldEndIt =
                tickNumber 2

            testCases :
                List
                    { wallDescription : String
                    , startingPosition : World.Position
                    , direction : Angle
                    , drawingPositionItShouldNeverMakeItTo : World.DrawingPosition
                    }
            testCases =
                [ { wallDescription = "Top wall"
                  , startingPosition = ( 100, 2.5 )
                  , direction = Angle (pi / 2)
                  , drawingPositionItShouldNeverMakeItTo = { leftEdge = 99, topEdge = -1 }
                  }
                , { wallDescription = "Right wall"
                  , startingPosition = ( 556.5, 100 )
                  , direction = Angle 0
                  , drawingPositionItShouldNeverMakeItTo = { leftEdge = 557, topEdge = 99 }
                  }
                , { wallDescription = "Bottom wall"
                  , startingPosition = ( 100, 477.5 )
                  , direction = Angle (-pi / 2)
                  , drawingPositionItShouldNeverMakeItTo = { leftEdge = 99, topEdge = 478 }
                  }
                , { wallDescription = "Left wall"
                  , startingPosition = ( 2.5, 100 )
                  , direction = Angle pi
                  , drawingPositionItShouldNeverMakeItTo = { leftEdge = -1, topEdge = 99 }
                  }
                ]
         in
         testCases
            |> List.map
                (\{ wallDescription, startingPosition, direction, drawingPositionItShouldNeverMakeItTo } ->
                    test wallDescription <|
                        \_ ->
                            let
                                green : Kurve
                                green =
                                    makeZombieKurve
                                        { color = Color.green
                                        , id = 3
                                        , state =
                                            { position = startingPosition
                                            , direction = direction
                                            , holeStatus = Unholy 60000
                                            }
                                        }

                                initialState : RoundInitialState
                                initialState =
                                    { seedAfterSpawn = Random.initialSeed 0
                                    , spawnedKurves = [ green ]
                                    }
                            in
                            initialState
                                |> expectRoundOutcome
                                    Config.default
                                    { tickThatShouldEndIt = tickThatShouldEndIt
                                    , howItShouldEnd =
                                        \round ->
                                            case ( round.kurves.alive, round.kurves.dead ) of
                                                ( [], [ deadKurve ] ) ->
                                                    let
                                                        theDrawingPositionItNeverMadeItTo : World.DrawingPosition
                                                        theDrawingPositionItNeverMadeItTo =
                                                            World.drawingPosition deadKurve.state.position
                                                    in
                                                    theDrawingPositionItNeverMadeItTo
                                                        |> Expect.equal drawingPositionItShouldNeverMakeItTo

                                                _ ->
                                                    Expect.fail "Expected exactly one dead Kurve and no alive ones"
                                    }
                )
        )


{-|


## Crash timing predictability

When a Kurve is traveling almost horizontally or vertically, it very obviously "snaps over to the next pixel row/column" at regular intervals.
When approaching a horizontal or vertical obstacle (wall or Kurve) from a shallow angle, an experienced player can easily tell based on the "snaps" exactly when they need to turn away to avoid crashing, because that will always happen at a "snap", never in the middle of a continuous "segment".

For example, the illustration below shows the exact moment when Green crashes into Red.

Notably, Green enjoys a full "segment" right next to Red before dying.
It would be highly surprising (at least to an experienced player) if Green would crash any earlier, because that would never happen in the original game.

    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛
    🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛
    🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    🟩🟩🟩🟩🟩🟩🟩🟩🟩⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛
    ⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛

-}
crashTimingTests : Test
crashTimingTests =
    describe "Crash timing"
        [ crashingIntoWallTimingTest
        , crashingIntoKurveTimingTests
        ]


crashingIntoWallTimingTest : Test
crashingIntoWallTimingTest =
    test "The exact timing of a crash into the wall is predictable for the player" <|
        \_ ->
            let
                currentKurve : Kurve
                currentKurve =
                    makeZombieKurve
                        { color = Color.white
                        , id = 5
                        , state =
                            { position = ( 100, 3.5 )
                            , direction = Angle 0.01
                            , holeStatus = Unholy 60000
                            }
                        }

                initialState : RoundInitialState
                initialState =
                    { seedAfterSpawn = Random.initialSeed 0
                    , spawnedKurves = [ currentKurve ]
                    }
            in
            initialState
                |> expectRoundOutcome
                    Config.default
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
                                    theDrawingPositionItNeverMadeItTo
                                        |> Expect.equal { leftEdge = 349, topEdge = -1 }

                                _ ->
                                    Expect.fail "Expected exactly one dead Kurve and no alive ones"
                    }


crashingIntoKurveTimingTests : Test
crashingIntoKurveTimingTests =
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
                                    makeZombieKurve
                                        { color = Color.red
                                        , id = 0
                                        , state =
                                            { position = ( 150, y_red )
                                            , direction = Angle 0
                                            , holeStatus = Unholy 60000
                                            }
                                        }

                                green : Kurve
                                green =
                                    makeZombieKurve
                                        { color = Color.green
                                        , id = 3
                                        , state =
                                            { position = ( 100, 107.5 )
                                            , direction = Angle 0.02
                                            , holeStatus = Unholy 60000
                                            }
                                        }

                                initialState : RoundInitialState
                                initialState =
                                    { seedAfterSpawn = Random.initialSeed 0
                                    , spawnedKurves = [ red, green ]
                                    }
                            in
                            initialState
                                |> expectRoundOutcome
                                    Config.default
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


cuttingCornersTests : Test
cuttingCornersTests =
    describe "Cutting corners (by painting over them)"
        [ test "It is possible to cut the corner of a Kurve's tail end" <|
            \_ ->
                let
                    red : Kurve
                    red =
                        makeZombieKurve
                            { color = Color.red
                            , id = 0
                            , state =
                                { position = ( 200.5, 100.5 )
                                , direction = Angle 0
                                , holeStatus = Unholy 60000
                                }
                            }

                    green : Kurve
                    green =
                        makeZombieKurve
                            { color = Color.green
                            , id = 3
                            , state =
                                { position = ( 100.5, 196.5 )
                                , direction = Angle (pi / 4)
                                , holeStatus = Unholy 60000
                                }
                            }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ red, green ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 277
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
                                                    |> Expect.equal { leftEdge = 295, topEdge = -1 }
                                            , \() ->
                                                deadKurve.color
                                                    |> Expect.equal Color.green
                                            ]
                                            ()

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and one alive one"
                        }
        , test "It is possible to paint over three pixels when cutting a corner (real example from original game)" <|
            \_ ->
                let
                    red : Kurve
                    red =
                        makeZombieKurve
                            { color = Color.red
                            , id = 0
                            , state =
                                { position = ( 299.5, 302.5 )
                                , direction = Angle (-71 * (2 * pi / 360))
                                , holeStatus = Unholy 60000
                                }
                            }

                    green : Kurve
                    green =
                        makeZombieKurve
                            { color = Color.green
                            , id = 3
                            , state =
                                { position = ( 319, 269 )
                                , direction = Angle (-123 * (2 * pi / 360))
                                , holeStatus = Unholy 60000
                                }
                            }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ red, green ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 40
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
                                                    |> Expect.equal { leftEdge = 296, topEdge = 301 }
                                            , \() ->
                                                deadKurve.color
                                                    |> Expect.equal Color.green
                                            ]
                                            ()

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and one alive one"
                        }
        , test "The perfect overpainting (NOT confirmed in original game)" <|
            \_ ->
                let
                    red : Kurve
                    red =
                        makeZombieKurve
                            { color = Color.red
                            , id = 0
                            , state =
                                { position = ( 30.5, 30.5 )
                                , direction = Angle (-pi / 4)
                                , holeStatus = Unholy 60000
                                }
                            }

                    yellow : Kurve
                    yellow =
                        makeZombieKurve
                            { color = Color.yellow
                            , id = 1
                            , state =
                                { position = ( 60.5, 60.5 )
                                , direction = Angle (-pi / 4)
                                , holeStatus = Unholy 60000
                                }
                            }

                    green : Kurve
                    green =
                        makeZombieKurve
                            { color = Color.green
                            , id = 3
                            , state =
                                { position = ( 19.5, 98.5 )
                                , direction = Angle (pi / 4)
                                , holeStatus = Unholy 60000
                                }
                            }

                    initialState : RoundInitialState
                    initialState =
                        { seedAfterSpawn = Random.initialSeed 0
                        , spawnedKurves = [ red, yellow, green ]
                        }
                in
                initialState
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 138
                        , howItShouldEnd =
                            \round ->
                                case ( round.kurves.alive, round.kurves.dead ) of
                                    ( [ _ ], [ secondDeadKurve, _ ] ) ->
                                        let
                                            theDrawingPositionItNeverMadeItTo : World.DrawingPosition
                                            theDrawingPositionItNeverMadeItTo =
                                                World.drawingPosition secondDeadKurve.state.position
                                        in
                                        Expect.all
                                            [ \() ->
                                                theDrawingPositionItNeverMadeItTo
                                                    |> Expect.equal { leftEdge = 116, topEdge = -1 }
                                            , \() ->
                                                secondDeadKurve.color
                                                    |> Expect.equal Color.green
                                            ]
                                            ()

                                    _ ->
                                        Expect.fail "Expected exactly two dead Kurves and one alive one"
                        }
        ]


speedTests : Test
speedTests =
    describe "Kurve speed"
        ([ ( Speed 60, tickNumber 450 )
         , ( Speed 120, tickNumber 225 )
         , ( Speed 180, tickNumber 150 )
         ]
            |> List.map
                (\( speed, expectedEndTick ) ->
                    test ("Round ends as expected when speed is " ++ String.fromFloat (Speed.toFloat speed)) <|
                        \_ ->
                            let
                                green : Kurve
                                green =
                                    makeZombieKurve
                                        { color = Color.green
                                        , id = 3
                                        , state =
                                            { position = ( 108, 100 )
                                            , direction = Angle 0
                                            , holeStatus = Unholy 60000
                                            }
                                        }

                                initialState : RoundInitialState
                                initialState =
                                    { seedAfterSpawn = Random.initialSeed 0
                                    , spawnedKurves = [ green ]
                                    }
                            in
                            initialState
                                |> expectRoundOutcome
                                    (defaultConfigWithSpeed speed)
                                    { tickThatShouldEndIt = expectedEndTick
                                    , howItShouldEnd =
                                        \round ->
                                            case round.kurves.dead of
                                                [ deadKurve ] ->
                                                    let
                                                        theDrawingPositionItNeverMadeItTo : World.DrawingPosition
                                                        theDrawingPositionItNeverMadeItTo =
                                                            World.drawingPosition deadKurve.state.position
                                                    in
                                                    theDrawingPositionItNeverMadeItTo
                                                        |> Expect.equal { leftEdge = 557, topEdge = 99 }

                                                _ ->
                                                    Expect.fail "Expected exactly one dead Kurve"
                                    }
                )
        )


{-| A description of when and how a round should end.
-}
type alias RoundOutcome =
    { tickThatShouldEndIt : Tick
    , howItShouldEnd : Round -> Expect.Expectation
    }


expectRoundOutcome : Config -> RoundOutcome -> RoundInitialState -> Expect.Expectation
expectRoundOutcome config { tickThatShouldEndIt, howItShouldEnd } initialState =
    let
        ( actualEndTick, actualRoundResult ) =
            playOutRound config initialState
    in
    Expect.all
        [ \_ ->
            if actualEndTick == tickThatShouldEndIt then
                Expect.pass

            else
                Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it ended on tick " ++ showTick actualEndTick ++ "."
        , \_ -> howItShouldEnd actualRoundResult
        ]
        ()


playOutRound : Config -> RoundInitialState -> ( Tick, Round )
playOutRound config initialState =
    let
        recurse : Tick -> MidRoundState -> ( Tick, Round )
        recurse tick midRoundState =
            let
                tickResult : TickResult
                tickResult =
                    reactToTick config (Tick.succ tick) midRoundState |> Tuple.first
            in
            case tickResult of
                RoundKeepsGoing nextTick nextMidRoundState ->
                    recurse nextTick nextMidRoundState

                RoundEnds actualRoundResult ->
                    let
                        actualEndTick : Tick
                        actualEndTick =
                            Tick.succ tick
                    in
                    ( actualEndTick, actualRoundResult )

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


defaultConfigWithSpeed : Speed -> Config
defaultConfigWithSpeed speed =
    let
        defaultConfig : Config
        defaultConfig =
            Config.default

        defaultKurveConfig : KurveConfig
        defaultKurveConfig =
            defaultConfig.kurves
    in
    { defaultConfig
        | kurves =
            { defaultKurveConfig
                | speed = speed
            }
    }


{-| Creates a Kurve that just moves forward.
-}
makeZombieKurve : { color : Color.Color, id : PlayerId, state : Kurve.State } -> Kurve
makeZombieKurve { color, id, state } =
    { color = color
    , id = id
    , controls = ( Set.empty, Set.empty )
    , state = state
    , stateAtSpawn =
        { position = ( 0, 0 )
        , direction = Angle 0
        , holeStatus = Unholy 0
        }
    , reversedInteractions = []
    }


{-| How many ticks to wait before performing some action, and that action.

The number of ticks to wait is counted from the previous action (or, for the first action, from the beginning of the round).

-}
type alias CumulativeInteraction =
    ( Int, TurningState )


{-| Makes it easy for a human to "program" a Kurve.

The input is a chronologically ordered list representing how a human will typically think about a Kurve's actions.

-}
makeUserInteractions : List CumulativeInteraction -> List UserInteraction
makeUserInteractions cumulativeInteractions =
    let
        accumulate : CumulativeInteraction -> ( List CumulativeInteraction, Int ) -> ( List CumulativeInteraction, Int )
        accumulate ( ticksBeforeAction, turningState ) ( soFar, previousTickNumber ) =
            let
                thisTickNumber : Int
                thisTickNumber =
                    previousTickNumber + ticksBeforeAction
            in
            ( ( thisTickNumber, turningState ) :: soFar, thisTickNumber )

        toUserInteraction : CumulativeInteraction -> UserInteraction
        toUserInteraction ( n, turningState ) =
            HappenedBefore (tickNumber n) turningState
    in
    List.foldl accumulate ( [], 0 ) cumulativeInteractions |> Tuple.first |> List.map toUserInteraction
