module TestScenarios.CrashIntoWallRight exposing (expectedOutcome, spawnedKurves)

import Color
import TestScenarioHelpers exposing (RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 555.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 2
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 557, topEdge = 99 }
              }
            ]
        }
    }
