module TestScenarios.CrashIntoWallLeft exposing (spawnedKurves)

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
            { position = ( 2.5, 100 )
            , direction = Angle (3 * pi / 2)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]
