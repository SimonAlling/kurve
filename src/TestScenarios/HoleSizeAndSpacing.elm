module TestScenarios.HoleSizeAndSpacing exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import Holes exposing (HoleStatus(..), Holiness(..))
import Random
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Distance exposing (Distance(..))
import Types.Kurve exposing (Kurve)


{-| The size of a segment between holes, measured from edge to edge.
-}
holeSpacing : Distance
holeSpacing =
    Distance 7


{-| The size of a hole, measured from edge to edge.
-}
holeGap : Distance
holeGap =
    Distance 3


config : Config
config =
    Config.default
        |> Config.withHardcodedHoles holeSpacing holeGap


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
                    { holiness = Unholy
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
              DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 458 } ) ]
                }

            -- Spawn is drawn permanently:
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

            -- The Kurve reaches a drawing position that, if drawn, would leave a 0px gap (i.e. the first drawing position that doesn't overlap with its last drawn position):
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 461 } ) ]
                }

            -- The Kurve reaches a drawing position that, if drawn, would leave a 1px gap:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 462 } ) ]
                }

            -- The Kurve reaches a drawing position that, if drawn, would leave a 2px gap:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 463 } ) ]
                }

            -- The Kurve reaches a drawing position that, when drawn, leaves a 3px gap:
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

            -- The Kurve reaches a drawing position that completes the 7px long segment between the holes:
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

            -- The Kurve reaches a drawing position that, if drawn, would leave a 0px gap:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 471 } ) ]
                }

            -- The Kurve reaches a drawing position that, if drawn, would leave a 1px gap:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 472 } ) ]
                }

            -- The Kurve reaches a drawing position that, if drawn, would leave a 2px gap:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { x = 100, y = 473 } ) ]
                }

            -- The Kurve reaches a drawing position that, when drawn, leaves a 3px gap:
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
