module TestScenarios.CrashIntoWallExactTiming exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    Config.default


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 99.5, 2.5 )
            , direction = Angle (pi / 2 + 0.01)
            , holeStatus =
                NoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 351
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 450, y = -1 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
