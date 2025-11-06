module AchtungTest exposing (tests)

import Color
import Config
import String
import Test exposing (Test, describe, test)
import TestHelpers exposing (defaultConfigWithSpeed, expectRoundOutcome)
import TestScenarioHelpers exposing (makeZombieKurve, playerIds, roundWith, tickNumber)
import TestScenarios.AroundTheWorld
import TestScenarios.CrashIntoTailEnd90Degrees
import TestScenarios.CrashIntoTipOfTailEnd
import TestScenarios.CrashIntoWallBasic
import TestScenarios.CrashIntoWallBottom
import TestScenarios.CrashIntoWallExactTiming
import TestScenarios.CrashIntoWallLeft
import TestScenarios.CrashIntoWallRight
import TestScenarios.CrashIntoWallTop
import TestScenarios.CuttingCornersBasic
import TestScenarios.CuttingCornersPerfectOverpainting
import TestScenarios.CuttingCornersThreePixelsRealExample
import TestScenarios.SpeedEffectOnGame
import TestScenarios.StressTestRealisticTurtleSurvivalRound
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Speed as Speed exposing (Speed(..))


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
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = -1, topEdge = 99 }
                                  }
                                ]
                            }
                        }
        , test "Around the world, touching each wall" <|
            \_ ->
                roundWith TestScenarios.AroundTheWorld.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 2011
                        , howItShouldEnd =
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 0, topEdge = -1 }
                                  }
                                ]
                            }
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
                            { aliveAtTheEnd = [ { id = playerIds.red } ]
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 97, topEdge = 101 }
                                  }
                                ]
                            }
                        }
        , test "Hitting a Kurve's tail end at a 45-degree angle is a crash" <|
            \_ ->
                roundWith TestScenarios.CrashIntoTipOfTailEnd.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 39
                        , howItShouldEnd =
                            { aliveAtTheEnd = [ { id = playerIds.red } ]
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 57, topEdge = 57 }
                                  }
                                ]
                            }
                        }
        ]


crashingIntoWallTests : Test
crashingIntoWallTests =
    describe "Crashing into a wall"
        [ test "Top wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallTop.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 2
                        , howItShouldEnd =
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 99, topEdge = -1 }
                                  }
                                ]
                            }
                        }
        , test "Right wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallRight.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 2
                        , howItShouldEnd =
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 557, topEdge = 99 }
                                  }
                                ]
                            }
                        }
        , test "Bottom wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallBottom.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 2
                        , howItShouldEnd =
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 99, topEdge = 478 }
                                  }
                                ]
                            }
                        }
        , test "Left wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallLeft.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 2
                        , howItShouldEnd =
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = -1, topEdge = 99 }
                                  }
                                ]
                            }
                        }
        ]


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
                        { aliveAtTheEnd = []
                        , deadAtTheEnd =
                            [ { id = playerIds.green
                              , theDrawingPositionItNeverMadeItTo = { leftEdge = 349, topEdge = -1 }
                              }
                            ]
                        }
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
                                        { aliveAtTheEnd = [ { id = playerIds.red } ]
                                        , deadAtTheEnd =
                                            [ { id = playerIds.green
                                              , theDrawingPositionItNeverMadeItTo = { leftEdge = 324, topEdge = 101 }
                                              }
                                            ]
                                        }
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
                            { aliveAtTheEnd = [ { id = playerIds.red } ]
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 295, topEdge = -1 }
                                  }
                                ]
                            }
                        }
        , test "It is possible to paint over three pixels when cutting a corner (real example from original game)" <|
            \_ ->
                roundWith TestScenarios.CuttingCornersThreePixelsRealExample.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 40
                        , howItShouldEnd =
                            { aliveAtTheEnd = [ { id = playerIds.red } ]
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 296, topEdge = 301 }
                                  }
                                ]
                            }
                        }
        , test "The perfect overpainting (squeezing through a non-existent gap)" <|
            \_ ->
                roundWith TestScenarios.CuttingCornersPerfectOverpainting.spawnedKurves
                    |> expectRoundOutcome
                        Config.default
                        { tickThatShouldEndIt = tickNumber 138
                        , howItShouldEnd =
                            { aliveAtTheEnd = [ { id = playerIds.yellow } ]
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 116, topEdge = -1 }
                                  }
                                , { id = playerIds.red
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 57, topEdge = 57 }
                                  }
                                ]
                            }
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
                                        { aliveAtTheEnd = []
                                        , deadAtTheEnd =
                                            [ { id = playerIds.green
                                              , theDrawingPositionItNeverMadeItTo = { leftEdge = 557, topEdge = 99 }
                                              }
                                            ]
                                        }
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
                            { aliveAtTheEnd = []
                            , deadAtTheEnd =
                                [ { id = playerIds.green
                                  , theDrawingPositionItNeverMadeItTo = { leftEdge = 372, topEdge = 217 }
                                  }
                                ]
                            }
                        }
        ]
