module TestScenarios.CrashIntoWallTop exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    Config.default


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
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
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 3 } ) ]
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 2 } ) ]
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 2 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 1 } ) ]
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 1 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 0 } ) ]
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { leftEdge = 99, topEdge = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
