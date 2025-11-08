module TestScenarios.CuttingCornersPerfectOverpainting exposing (expectedOutcome, spawnedKurves)

import Color
import TestScenarioHelpers exposing (RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


red : Kurve
red =
    makeZombieKurve
        { color = Color.red
        , id = playerIds.red
        , state =
            { position = ( 30.5, 30.5 )
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
            { position = ( 88.5, 88.5 )
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
            { position = ( 100, 400 )
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
            { position = ( 19.5, 98.5 )
            , direction = Angle (3 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, yellow, orange, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 138
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.yellow } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 116, topEdge = -1 }
              }
            , { id = playerIds.red
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 57, topEdge = 57 }
              }
            ]
        }
    }
