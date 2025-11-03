module TestScenarios.CuttingCornersPerfectOverpaintingTheoretical exposing (spawnedKurves)

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
            { position = ( 30.5, 30.5 )
            , direction = Angle (-pi / 4)
            , holeStatus = Unholy 60000
            }
        }


yellow : Kurve
yellow =
    makeZombieKurve
        { color = Color.yellow
        , id = playerIds.yellow
        , state =
            { position = ( 60.5, 60.5 )
            , direction = Angle (-pi / 4)
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 19.5, 98.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green, yellow ]
