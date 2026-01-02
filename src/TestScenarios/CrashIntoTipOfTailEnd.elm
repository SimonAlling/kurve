module TestScenarios.CrashIntoTipOfTailEnd exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    Config.default


red : Kurve
red =
    makeZombieKurve
        { color = Colors.red
        , id = playerIds.red
        , state =
            { position = ( 59.5, 59.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 29.5, 29.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 39
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.red } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 57, topEdge = 57 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
