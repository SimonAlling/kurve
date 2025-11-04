module TestScenarios.CrashIntoWallExactTiming exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 100, 3.5 )
            , direction = Angle 0.01
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]
