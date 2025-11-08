module TestScenarios.CrashIntoKurveTiming exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


red : Float -> Kurve
red y_red =
    makeZombieKurve
        { color = Color.red
        , id = playerIds.red
        , state =
            { position = ( 150, y_red )
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
            { position = ( 100, 107.5 )
            , direction = Angle (pi / 2 + 0.02)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : Float -> List Kurve
spawnedKurves y_red =
    [ red y_red, green ]
