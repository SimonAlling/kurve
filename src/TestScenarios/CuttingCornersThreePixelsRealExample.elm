module TestScenarios.CuttingCornersThreePixelsRealExample exposing (spawnedKurves)

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
            { position = ( 299.5, 302.5 )
            , direction = Angle (-71 * (2 * pi / 360))
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = 3
        , state =
            { position = ( 319, 269 )
            , direction = Angle (-123 * (2 * pi / 360))
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]
