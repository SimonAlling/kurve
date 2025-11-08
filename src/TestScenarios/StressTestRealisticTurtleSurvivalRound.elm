module TestScenarios.StressTestRealisticTurtleSurvivalRound exposing (spawnedKurves)

import Color
import TestScenarioHelpers exposing (CumulativeInteraction, makeUserInteractions, makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.TurningState exposing (TurningState(..))


greenZombie : Kurve
greenZombie =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 32.5, 3.5 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    { greenZombie
        | reversedInteractions =
            List.range 1 20
                |> List.concatMap makeLap
                |> makeUserInteractions
    }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


makeLap : Int -> List CumulativeInteraction
makeLap i =
    [ ( 510 - 20 * i, TurningRight )
    , ( 45, NotTurning )
    , ( 430 - 20 * i, TurningRight )
    , ( 45, NotTurning )
    , ( 495 - 20 * i, TurningRight )
    , ( 44, NotTurning )
    , ( 414 - 20 * i, TurningRight )
    , ( 45, NotTurning )
    ]
