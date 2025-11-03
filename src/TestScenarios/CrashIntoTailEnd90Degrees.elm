module TestScenarios.CrashIntoTailEnd90Degrees exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


red : Kurve
red =
    makeZombieKurve
        { color = Color.red
        , id = playerIds.red
        , state =
            { position = ( 100.5, 100.5 )
            , direction = Angle 0
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 98.5, 110.5 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]
