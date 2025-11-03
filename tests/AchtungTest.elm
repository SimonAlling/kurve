module AchtungTest exposing (tests)

import Color
import Config
import Expect
import String
import Test exposing (Test, describe, test)
import TestHelpers exposing (defaultConfigWithSpeed, expectRoundOutcome)
import TestScenarioHelpers exposing (makeZombieKurve, playerIds, roundWith, tickNumber)
import TestScenarios.AroundTheWorld
import TestScenarios.CrashIntoTailEnd90Degrees
import TestScenarios.CrashIntoTipOfTailEnd
import TestScenarios.CrashIntoWallBasic
import TestScenarios.CrashIntoWallExactTiming
import TestScenarios.CuttingCornersBasic
import TestScenarios.CuttingCornersPerfectOverpaintingTheoretical
import TestScenarios.CuttingCornersThreePixelsRealExample
import TestScenarios.SpeedEffectOnGame
import TestScenarios.StressTestRealisticTurtleSurvivalRound
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Speed as Speed exposing (Speed(..))
import Types.Tick exposing (Tick)
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
        , stressTests
        ]


basicTests : Test
basicTests =
    describe "Basic tests"
        [ test "A Kurve that crashes into the wall dies" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallBasic.spawnedKurves
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
                roundWith TestScenarios.AroundTheWorld.spawnedKurves
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
                roundWith TestScenarios.CrashIntoTailEnd90Degrees.spawnedKurves
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
                roundWith TestScenarios.CrashIntoTipOfTailEnd.spawnedKurves
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
                                        , id = playerIds.green
                                        , state =
                                            { position = startingPosition
                                            , direction = direction
                                            , holeStatus = Unholy 60000
                                            }
                                        }
                            in
                            roundWith [ green ]
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
            roundWith TestScenarios.CrashIntoWallExactTiming.spawnedKurves
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
                                        , id = playerIds.red
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
                                        , id = playerIds.green
                                        , state =
                                            { position = ( 100, 107.5 )
                                            , direction = Angle 0.02
                                            , holeStatus = Unholy 60000
                                            }
                                        }
                            in
                            roundWith [ red, green ]
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
                roundWith TestScenarios.CuttingCornersBasic.spawnedKurves
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
                roundWith TestScenarios.CuttingCornersThreePixelsRealExample.spawnedKurves
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
        , test "The perfect overpainting (squeezing through a non-existent gap)" <|
            \_ ->
                roundWith TestScenarios.CuttingCornersPerfectOverpaintingTheoretical.spawnedKurves
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
                            roundWith TestScenarios.SpeedEffectOnGame.spawnedKurves
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


stressTests : Test
stressTests =
    describe "Stress tests"
        [ test "Realistic single-player turtle survival round" <|
            \_ ->
                roundWith TestScenarios.StressTestRealisticTurtleSurvivalRound.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 23875
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
                                            |> Expect.equal { leftEdge = 372, topEdge = 217 }

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve"
                        }
        ]
