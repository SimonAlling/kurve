module TestScenarios.CrashIntoWallTop exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Random
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Holiness(..), Kurve)


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
            , holeStatus =
                { holiness = Unholy
                , ticksLeft = 60000
                , holeSeed = Random.initialSeed 0
                }
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
              , theDrawingPositionItNeverMadeItTo = { x = 99, y = -1 }
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
                , headDrawing = [ ( Colors.green, { x = 99, y = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 3 } ) ]
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 2 } ) ]
                , headDrawing = [ ( Colors.green, { x = 99, y = 2 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 1 } ) ]
                , headDrawing = [ ( Colors.green, { x = 99, y = 1 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 0 } ) ]
                , headDrawing = [ ( Colors.green, { x = 99, y = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
