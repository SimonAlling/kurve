module TestScenarios.CrashIntoWallTop exposing (expectedOutcome, spawnedKurves)

import Color
import Effect exposing (Effect(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 99.5, 3.5 )
            , direction = Angle pi
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 5
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 99, topEdge = -1 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 3 } ) ]
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 2 } ) ]
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 2 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 1 } ) ]
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 1 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 0 } ) ]
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 99, topEdge = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
