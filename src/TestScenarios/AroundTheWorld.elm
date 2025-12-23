module TestScenarios.AroundTheWorld exposing (expectedOutcome, spawnedKurves)

import Color
import TestScenarioHelpers exposing (RoundOutcome, makeUserInteractions, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.TurningState exposing (TurningState(..))


greenZombie : Kurve
greenZombie =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 3.5, 0.5 )
            , direction = Angle (pi / 2)
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


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 2011
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 0, topEdge = -1 }
              }
            ]
        }
    }
