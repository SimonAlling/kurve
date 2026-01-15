module TestScenarios.AroundTheWorld exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleInit(..), HoleStatus(..), makeInitialHoleStatus)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeUserInteractions, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)
import Types.TurningState exposing (TurningState(..))


config : Config
config =
    Config.default


greenZombie : Kurve
greenZombie =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 3.5, 0.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                makeInitialHoleStatus config.kurves InitNoHoles
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
    { tickThatShouldEndIt = tickNumber 2012
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 0, y = -1 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
