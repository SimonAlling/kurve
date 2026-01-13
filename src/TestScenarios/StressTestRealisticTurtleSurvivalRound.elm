module TestScenarios.StressTestRealisticTurtleSurvivalRound exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import TestScenarioHelpers exposing (CumulativeInteraction, EffectsExpectation(..), RoundOutcome, makeUserInteractions, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.TurningState exposing (TurningState(..))


config : Config
config =
    Config.default


greenZombie : Kurve
greenZombie =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 31.5, 2.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                NoHoles
            }
        }


green : Kurve
green =
    { greenZombie
        | reversedInteractions =
            List.range 1 20
                |> List.concatMap makeLap
                |> makeUserInteractions
    }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


makeLap : Int -> List CumulativeInteraction
makeLap i =
    [ ( 510 - 20 * i, TurningRight )
    , ( 45, NotTurning )
    , ( 430 - 20 * i, TurningRight )
    , ( 45, NotTurning )
    , ( 495 - 20 * i, TurningRight )
    , ( 44, NotTurning )
    , ( 414 - 20 * i, TurningRight )
    , ( 45, NotTurning )
    ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 23875
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 372, y = 217 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
