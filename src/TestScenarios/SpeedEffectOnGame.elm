module TestScenarios.SpeedEffectOnGame exposing (expectedOutcome, spawnedKurves)

import Color
import TestScenarioHelpers exposing (RoundOutcome, makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Tick exposing (Tick)


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 108.5, 100.5 )
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
    }
