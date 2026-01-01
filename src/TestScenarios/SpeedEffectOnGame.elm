module TestScenarios.SpeedEffectOnGame exposing (config, expectedOutcome, spawnedKurves)

import Color
import Config exposing (Config)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, defaultConfigWithSpeed, makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Speed exposing (Speed)
import Types.Tick exposing (Tick)


config : Speed -> Config
config =
    defaultConfigWithSpeed


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 107.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
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
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 557, topEdge = 99 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
