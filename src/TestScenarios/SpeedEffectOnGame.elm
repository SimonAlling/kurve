module TestScenarios.SpeedEffectOnGame exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, defaultConfigWithSpeed, makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)
import Types.Speed exposing (Speed)
import Types.Tick exposing (Tick)


config : Speed -> Config
config =
    defaultConfigWithSpeed


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 107.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                NoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : Tick -> RoundOutcome
expectedOutcome expectedEndTick =
    { tickThatShouldEndIt = expectedEndTick
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
