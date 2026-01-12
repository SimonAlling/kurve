module TestScenarios.CrashIntoKurveTiming exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Random
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Holiness(..), Kurve)


config : Config
config =
    Config.default


red : Float -> Kurve
red y_red =
    makeZombieKurve
        { color = Colors.red
        , id = playerIds.red
        , state =
            { position = ( 149.5, y_red )
            , direction = Angle (pi / 2)
            , holeStatus =
                { holiness = Unholy 60000
                , holeSeed = Random.initialSeed 0
                }
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 99.5, 106.5 )
            , direction = Angle (pi / 2 + 0.02)
            , holeStatus =
                { holiness = Unholy 60000
                , holeSeed = Random.initialSeed 0
                }
            }
        }


spawnedKurves : Float -> List Kurve
spawnedKurves y_red =
    [ red y_red, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 226
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.red } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 325, y = 101 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
