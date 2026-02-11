module TestScenarios.CrashingAfterBecomingSolidAtSameDrawingPosition_Bottom exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Holes exposing (HoleStatus(..), Holiness(..))
import Random
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    Config.default
        |> Config.withHardcodedHoles 100 4


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 103.6, 473.6 )
            , direction = Angle (pi / 4)
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 1
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 7
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 108, y = 478 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ -- Spawning:
              DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 103, y = 473 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 103, y = 473 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 103, y = 473 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }

            -- Draw spawn position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 103, y = 473 } ) ]
                , headDrawing = []
                }

            -- Start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 104, y = 474 } ) ]
                , headDrawing = [ ( Colors.green, { x = 104, y = 474 } ) ]
                }

            -- Start of hole:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 105, y = 475 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 105, y = 475 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 106, y = 476 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 107, y = 477 } ) ]
                }

            -- Start of solid segment (note that drawing position is same as previous one):
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 107, y = 477 } ) ]
                , headDrawing = [ ( Colors.green, { x = 107, y = 477 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
