module TestScenarios.CrashIntoWallLeft exposing (config, expectedOutcome, spawnedKurves)

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
            { position = ( 3.5, 99.5 )
            , direction = Angle (3 * pi / 2)
            , holeStatus =
                { holiness = Unholy
                , ticksLeft = 60000
                , holeSeed = Random.initialSeed 0
                }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 5
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = -1, y = 99 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
