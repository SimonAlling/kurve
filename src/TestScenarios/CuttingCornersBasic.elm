module TestScenarios.CuttingCornersBasic exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (makeZombieKurve)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


red : Kurve
red =
    makeZombieKurve
        { color = Color.red
        , id = 0
        , state =
            { position = ( 200.5, 100.5 )
            , direction = Angle 0
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = 3
        , state =
            { position = ( 100.5, 196.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]
