module TestScenarios.CrashIntoWallRight exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Random
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Holiness(..), Kurve)


config : Config
config =
    Config.default


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 553.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                { holiness = Unholy 60000
                , holeSeed = Random.initialSeed 0
                }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 4
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 557, y = 99 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
