module TestScenarios.HoleSizeAndSpacing exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Holes exposing (HoleStatus(..), Holiness(..))
import Random
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


solidTicks : Int
solidTicks =
    5


holyTicks : Int
holyTicks =
    5


config : Config
config =
    Config.default
        |> Config.withHardcodedHoles solidTicks holyTicks


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 100, 458 )
            , direction = Angle 0
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 0
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 20
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
              DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }
            , DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }
            , DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }
            , DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }

            -- Spawn is drawn permanently:
            , DoNothing
            , DoNothing
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                , headDrawing = []
                }

            -- The Kurve starts moving and immediately opens a hole:
            , DrawSomething
                { bodyDrawing = []
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

            -- The Kurve closes the hole:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 464 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 464 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 465 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 465 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 466 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 466 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 467 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 467 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 468 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 468 } ) ]
                }

            -- The Kurve opens a new hole:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 469 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 470 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 471 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 472 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 473 } ) ]
                }

            -- The Kurve closes the hole:
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
