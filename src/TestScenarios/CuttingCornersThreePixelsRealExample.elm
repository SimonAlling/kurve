module TestScenarios.CuttingCornersThreePixelsRealExample exposing (spawnedKurves)

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
            { position = ( 299.5, 302.5 )
            , direction = Angle (-71 * (2 * pi / 360) + (pi / 2))
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 319, 269 )
            , direction = Angle (-123 * (2 * pi / 360) + (pi / 2))
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]
