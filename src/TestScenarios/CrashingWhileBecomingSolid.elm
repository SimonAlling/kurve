module TestScenarios.CrashingWhileBecomingSolid exposing (config, expectedOutcome, spawnedKurves)

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
        |> Config.withHardcodedHoles 98 7


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 546, 100 )
            , direction = Angle (pi / 2)
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 2
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 11
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 557, y = 100 }
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
                , headDrawing = [ ( Colors.green, { x = 546, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 546, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 546, y = 100 } ) ]
                }

            -- Draw spawn position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 546, y = 100 } ) ]
                , headDrawing = []
                }

            -- Start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 547, y = 100 } ) ]
                , headDrawing = [ ( Colors.green, { x = 547, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 548, y = 100 } ) ]
                , headDrawing = [ ( Colors.green, { x = 548, y = 100 } ) ]
                }

            -- Start of hole:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 549, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 550, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 551, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 552, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 553, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 554, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 555, y = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 556, y = 100 } ) ]
                }

            -- Draw death position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 556, y = 100 } ) ]
                , headDrawing = []
                }
            ]
    }
