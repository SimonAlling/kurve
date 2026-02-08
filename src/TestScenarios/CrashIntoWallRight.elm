module TestScenarios.CrashIntoWallRight exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    Config.default


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 553.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                NoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 4
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 557, y = 99 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 553, y = 99 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 553, y = 99 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 553, y = 99 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 553, y = 99 } ) ]
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 554, y = 99 } ) ]
                , headDrawing = [ ( Colors.green, { x = 554, y = 99 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 555, y = 99 } ) ]
                , headDrawing = [ ( Colors.green, { x = 555, y = 99 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 556, y = 99 } ) ]
                , headDrawing = [ ( Colors.green, { x = 556, y = 99 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
