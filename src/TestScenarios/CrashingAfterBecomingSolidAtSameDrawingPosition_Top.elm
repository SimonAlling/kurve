module TestScenarios.CrashingAfterBecomingSolidAtSameDrawingPosition_Top exposing (config, expectedOutcome, spawnedKurves)

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
        |> Config.withHardcodedHoles 100 8


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 100, 12.1 )
            , direction = Angle pi
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 4
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 14
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 100, y = -1 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ -- Spawning:
              DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 12 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 12 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 12 } ) ]
                }

            -- Draw spawn position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 12 } ) ]
                , headDrawing = []
                }

            -- Start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 11 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 11 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 10 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 10 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 9 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 9 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 8 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 8 } ) ]
                }

            -- Start of hole:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 7 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 6 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 5 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 4 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 3 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 2 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 1 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 0 } ) ]
                }

            -- Start of solid segment:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 100, y = 0 } ) ]
                , headDrawing = [ ( Colors.green, { x = 100, y = 0 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            ]
    }
