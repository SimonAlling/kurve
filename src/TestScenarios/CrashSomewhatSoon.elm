module TestScenarios.CrashSomewhatSoon exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)
import Types.Speed exposing (Speed(..))


config : Config
config =
    Config.default
        |> Config.withSpeed (Speed 180)


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 100.5, 460.5 )
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
    { tickThatShouldEndIt = tickNumber 6
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 100, y = 478 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ -- Spawning:
              DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 460 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 460 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 460 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }

            -- Draw spawn position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 460 } ) ]
                , headDrawing = []
                }

            -- Start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 461 } ), ( Colors.green, { x = 100, y = 462 } ), ( Colors.green, { x = 100, y = 463 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 463 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 464 } ), ( Colors.green, { x = 100, y = 465 } ), ( Colors.green, { x = 100, y = 466 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 466 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 467 } ), ( Colors.green, { x = 100, y = 468 } ), ( Colors.green, { x = 100, y = 469 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 469 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 470 } ), ( Colors.green, { x = 100, y = 471 } ), ( Colors.green, { x = 100, y = 472 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 472 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 473 } ), ( Colors.green, { x = 100, y = 474 } ), ( Colors.green, { x = 100, y = 475 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 475 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 476 } ), ( Colors.green, { x = 100, y = 477 } ) ]
                , headDrawing = []
                }
            ]
    }
