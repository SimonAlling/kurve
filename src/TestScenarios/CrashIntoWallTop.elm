module TestScenarios.CrashIntoWallTop exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, draw, makeZombieKurve, playerIds, tickNumber)
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
                , headDrawing = [ draw '🟩' ( 99, 3 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟩' ( 99, 3 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟩' ( 99, 3 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 99, 3 ) ]
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 99, 2 ) ]
                , headDrawing = [ draw '🟩' ( 99, 2 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 99, 1 ) ]
                , headDrawing = [ draw '🟩' ( 99, 1 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 99, 0 ) ]
                , headDrawing = [ draw '🟩' ( 99, 0 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟩' ( 99, 0 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
