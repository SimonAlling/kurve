module TestScenarios.PeriodicHoles exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Holes exposing (HoleStatus(..), Holiness(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Distance exposing (Distance(..))
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
            { position = ( 100, 450 )
            , direction = Angle 0
            , holeStatus =
                PeriodicHoles
                    { holiness = Unholy
                    , ticksLeft = 8
                    , interval = Distance 8
                    , size = Distance 4
                    }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 28
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
            [ DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 450 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 450 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 450 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 450 } ) ]
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 451 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 451 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 452 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 452 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 453 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 453 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 454 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 454 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 455 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 455 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 456 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 456 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 457 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 457 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 459 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 459 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 460 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 461 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 462 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 463 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 464 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 465 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 466 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 467 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 468 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 468 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 469 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 469 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 470 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 470 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 471 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 471 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 472 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 472 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 473 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 473 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 474 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 474 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 475 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 475 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 476 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 476 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 477 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 477 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
