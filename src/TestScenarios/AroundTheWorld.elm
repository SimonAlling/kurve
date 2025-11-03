module TestScenarios.AroundTheWorld exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (makeUserInteractions, makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.TurningState exposing (TurningState(..))


greenZombie : Kurve
greenZombie =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 4.5, 1.5 )
            , direction = Angle 0
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    { greenZombie
        | reversedInteractions =
            makeUserInteractions
                -- Intended to make the Kurve touch each of the four walls on its way around the world.
                [ ( 526, TurningRight )
                , ( 45, NotTurning )
                , ( 420, TurningRight )
                , ( 45, NotTurning )
                , ( 491, TurningRight )
                , ( 44, NotTurning )
                ]
    }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]
