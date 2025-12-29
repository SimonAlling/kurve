module TestScenarios.CuttingCornersPerfectOverpainting exposing (expectedOutcome, spawnedKurves)

import Color
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


red : Kurve
red =
    makeZombieKurve
        { color = Color.red
        , id = playerIds.red
        , state =
            { position = ( 29.5, 29.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


yellow : Kurve
yellow =
    makeZombieKurve
        { color = Color.yellow
        , id = playerIds.yellow
        , state =
            { position = ( 87.5, 87.5 )
            , direction = Angle (5 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


orange : Kurve
orange =
    makeZombieKurve
        { color = Color.orange
        , id = playerIds.orange
        , state =
            { position = ( 99.5, 399.5 )
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
            { position = ( 18.5, 97.5 )
            , direction = Angle (3 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, yellow, orange, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 140
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.orange } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 117, topEdge = -1 }
              }
            , { id = playerIds.yellow
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 58, topEdge = 58 }
              }
            , { id = playerIds.red
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 57, topEdge = 57 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
