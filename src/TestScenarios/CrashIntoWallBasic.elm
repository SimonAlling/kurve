module TestScenarios.CrashIntoWallBasic exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (makeZombieKurve)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = 3
        , state =
            { position = ( 2.5, 100 )
            , direction = Angle pi
            , holeStatus = Unholy 60
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]
