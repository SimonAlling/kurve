module TestScenarios.CrashIntoKurveTiming exposing (config, expectedOutcome, spawnedKurves)

import Color
import Config exposing (Config)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    Config.default


red : Float -> Kurve
red y_red =
    makeZombieKurve
        { color = Color.red
        , id = playerIds.red
        , state =
            { position = ( 149.5, y_red )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 99.5, 106.5 )
            , direction = Angle (pi / 2 + 0.02)
            , holeStatus = Unholy 60000
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
