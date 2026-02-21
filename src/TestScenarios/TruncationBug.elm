module TestScenarios.TruncationBug exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, andProgramIt, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)
import Types.TurningState exposing (TurningState(..))


config : Bool -> Config
config replicateTruncationBug =
    Config.default
        |> Config.withReplicateTruncationBug replicateTruncationBug


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 3.5, 400.5 )
            , direction = Angle -0.1
            , holeStatus =
                NoHoles
            }
        }
        |> andProgramIt
            [ ( 45, TurningLeft )
            , ( 7, NotTurning )
            ]


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : Bool -> RoundOutcome
expectedOutcome replicateTruncationBug =
    if replicateTruncationBug then
        expectedOutcomeWithBug

    else
        expectedOutcomeWithoutBug


expectedOutcomeWithoutBug : RoundOutcome
expectedOutcomeWithoutBug =
    { tickThatShouldEndIt = tickNumber 36
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = -1, y = 436 }
              }
            ]
        }
    , effectsItShouldProduce =
        DoNotCare
    }


expectedOutcomeWithBug : RoundOutcome
expectedOutcomeWithBug =
    { tickThatShouldEndIt = tickNumber 79
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 3, y = 478 }
              }
            ]
        }
    , effectsItShouldProduce =
        DoNotCare
    }
