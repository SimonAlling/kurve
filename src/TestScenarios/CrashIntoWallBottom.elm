module TestScenarios.CrashIntoWallBottom exposing (config, expectedOutcome, spawnedKurves)

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
            { position = ( 99.5, 474.5 )
            , direction = Angle 0
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
              , theDrawingPositionItNeverMadeItTo = { x = 99, y = 478 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ -- Spawning:
              DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }

            -- Draw spawn position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 474 } ) ]
                , headDrawing = []
                }

            -- Start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 475 } ) ]
                , headDrawing = [ ( Colors.green, { x = 99, y = 475 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 476 } ) ]
                , headDrawing = [ ( Colors.green, { x = 99, y = 476 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 99, y = 477 } ) ]
                , headDrawing = [ ( Colors.green, { x = 99, y = 477 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
