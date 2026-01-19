module AchtungTest exposing (tests)

import String
import Test exposing (Test, describe, test)
import TestHelpers exposing (expectRoundOutcome)
import TestScenarioHelpers exposing (roundWith, tickNumber)
import TestScenarios.AroundTheWorld
import TestScenarios.CrashIntoKurveTiming
import TestScenarios.CrashIntoTailEnd90Degrees
import TestScenarios.CrashIntoTipOfTailEnd
import TestScenarios.CrashIntoWallBottom
import TestScenarios.CrashIntoWallExactTiming
import TestScenarios.CrashIntoWallLeft
import TestScenarios.CrashIntoWallRight
import TestScenarios.CrashIntoWallTop
import TestScenarios.CrashSomewhatSoon
import TestScenarios.CrashingWhileBecomingUnholy
import TestScenarios.CuttingCornersBasic
import TestScenarios.CuttingCornersPerfectOverpainting
import TestScenarios.HoleTiming
import TestScenarios.SpeedEffectOnGame
import TestScenarios.StressTestRealisticTurtleSurvivalRound
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
        , holeTests
        , drawingTests
        ]


basicTests : Test
basicTests =
    describe "Basic tests"
        [ test "Around the world, touching each wall" <|
            \_ ->
                roundWith TestScenarios.AroundTheWorld.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.AroundTheWorld.config
                        TestScenarios.AroundTheWorld.expectedOutcome
        ]


crashingIntoKurveTests : Test
crashingIntoKurveTests =
    describe "Crashing into a Kurve"
        [ test "Hitting a Kurve's tail end is a crash" <|
            \_ ->
                roundWith TestScenarios.CrashIntoTailEnd90Degrees.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashIntoTailEnd90Degrees.config
                        TestScenarios.CrashIntoTailEnd90Degrees.expectedOutcome
        , test "Hitting a Kurve's tail end at a 45-degree angle is a crash" <|
            \_ ->
                roundWith TestScenarios.CrashIntoTipOfTailEnd.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashIntoTipOfTailEnd.config
                        TestScenarios.CrashIntoTipOfTailEnd.expectedOutcome
        ]


crashingIntoWallTests : Test
crashingIntoWallTests =
    describe "Crashing into a wall"
        [ test "Top wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallTop.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashIntoWallTop.config
                        TestScenarios.CrashIntoWallTop.expectedOutcome
        , test "Right wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallRight.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashIntoWallRight.config
                        TestScenarios.CrashIntoWallRight.expectedOutcome
        , test "Bottom wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallBottom.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashIntoWallBottom.config
                        TestScenarios.CrashIntoWallBottom.expectedOutcome
        , test "Left wall" <|
            \_ ->
                roundWith TestScenarios.CrashIntoWallLeft.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashIntoWallLeft.config
                        TestScenarios.CrashIntoWallLeft.expectedOutcome
        ]


{-|


## Crash timing predictability

When a Kurve is traveling almost horizontally or vertically, it very obviously "snaps over to the next pixel row/column" at regular intervals.
When approaching a horizontal or vertical obstacle (wall or Kurve) from a shallow angle, an experienced player can easily tell based on the "snaps" exactly when they need to turn away to avoid crashing, because that will always happen at a "snap", never in the middle of a continuous "segment".

However, the top and left walls are exceptions to the rule in the sense that the player can enjoy an _extra_ segment before crashing.
That is, it's effectively possible to be up to (but not including) 1 pixel _outside_ the canvas at the top and left borders, but the _rendered_ Kurve and its hitbox are always fully within the canvas.

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
                    TestScenarios.CrashIntoWallExactTiming.config
                    TestScenarios.CrashIntoWallExactTiming.expectedOutcome


crashingIntoKurveTimingTests : Test
crashingIntoKurveTimingTests =
    describe "The exact timing of a crash into a Kurve is predictable for the player"
        (List.range 0 9
            |> List.map
                (\decimal ->
                    let
                        y_red : Float
                        y_red =
                            99 + toFloat decimal / 10
                    in
                    test
                        ("When Red's vertical position is " ++ String.fromFloat y_red)
                        (\_ ->
                            roundWith (TestScenarios.CrashIntoKurveTiming.spawnedKurves y_red)
                                |> expectRoundOutcome
                                    TestScenarios.CrashIntoKurveTiming.config
                                    TestScenarios.CrashIntoKurveTiming.expectedOutcome
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
                        TestScenarios.CuttingCornersBasic.config
                        TestScenarios.CuttingCornersBasic.expectedOutcome
        , test "The perfect overpainting (squeezing through a non-existent gap)" <|
            \_ ->
                roundWith TestScenarios.CuttingCornersPerfectOverpainting.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CuttingCornersPerfectOverpainting.config
                        TestScenarios.CuttingCornersPerfectOverpainting.expectedOutcome
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
                                    (TestScenarios.SpeedEffectOnGame.config speed)
                                    (TestScenarios.SpeedEffectOnGame.expectedOutcome expectedEndTick)
                )
        )


stressTests : Test
stressTests =
    describe "Stress tests"
        [ test "Realistic single-player turtle survival round" <|
            \_ ->
                roundWith TestScenarios.StressTestRealisticTurtleSurvivalRound.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.StressTestRealisticTurtleSurvivalRound.config
                        TestScenarios.StressTestRealisticTurtleSurvivalRound.expectedOutcome
        ]


drawingTests : Test
drawingTests =
    describe "Drawing tests"
        [ test "Drawing positions are described in chronological order" <|
            \_ ->
                roundWith TestScenarios.CrashSomewhatSoon.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashSomewhatSoon.config
                        TestScenarios.CrashSomewhatSoon.expectedOutcome
        ]


holeTests : Test
holeTests =
    describe "Hole tests"
        [ test "Final head position is drawn when simultaneously crashing and becoming unholy" <|
            \_ ->
                roundWith TestScenarios.CrashingWhileBecomingUnholy.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.CrashingWhileBecomingUnholy.config
                        TestScenarios.CrashingWhileBecomingUnholy.expectedOutcome
        , test "Hole timing is correct" <|
            \_ ->
                roundWith TestScenarios.HoleTiming.spawnedKurves
                    |> expectRoundOutcome
                        TestScenarios.HoleTiming.config
                        TestScenarios.HoleTiming.expectedOutcome
        ]
