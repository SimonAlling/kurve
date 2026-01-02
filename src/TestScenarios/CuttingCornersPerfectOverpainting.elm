module TestScenarios.CuttingCornersPerfectOverpainting exposing (config, expectedOutcome, spawnedKurves)

import Color
import Config exposing (Config)
import Effect exposing (Effect(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    Config.default


red : Kurve
red =
    makeZombieKurve
        { color = Color.red
        , id = playerIds.red
        , state =
            { position = ( 29.5, 29.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


yellow : Kurve
yellow =
    makeZombieKurve
        { color = Color.yellow
        , id = playerIds.yellow
        , state =
            { position = ( 37.5, 37.5 )
            , direction = Angle (5 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


orange : Kurve
orange =
    makeZombieKurve
        { color = Color.orange
        , id = playerIds.orange
        , state =
            { position = ( 20.5, 24.5 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 18.5, 47.5 )
            , direction = Angle (3 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, yellow, orange, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 29
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.orange } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 39, y = 26 }
              }
            , { id = playerIds.yellow
              , theDrawingPositionItNeverMadeItTo = { x = 33, y = 33 }
              }
            , { id = playerIds.red
              , theDrawingPositionItNeverMadeItTo = { x = 32, y = 32 }
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
                , headDrawing = [ ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { x = 18, y = 47 } ), ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { x = 18, y = 47 } ), ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { x = 18, y = 47 } ), ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                }

            -- Spawns are drawn permanently:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 18, y = 47 } ), ( Color.orange, { x = 20, y = 24 } ), ( Color.yellow, { x = 37, y = 37 } ), ( Color.red, { x = 29, y = 29 } ) ]
                , headDrawing = []
                }

            -- The Kurves start moving:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 19, y = 46 } ), ( Color.orange, { x = 21, y = 24 } ), ( Color.yellow, { x = 36, y = 36 } ), ( Color.red, { x = 30, y = 30 } ) ]
                , headDrawing = [ ( Color.red, { x = 30, y = 30 } ), ( Color.yellow, { x = 36, y = 36 } ), ( Color.orange, { x = 21, y = 24 } ), ( Color.green, { x = 19, y = 46 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 22, y = 24 } ) ]
                , headDrawing = [ ( Color.red, { x = 30, y = 30 } ), ( Color.yellow, { x = 36, y = 36 } ), ( Color.orange, { x = 22, y = 24 } ), ( Color.green, { x = 19, y = 46 } ) ]
                }

            -- Red's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 20, y = 45 } ), ( Color.orange, { x = 23, y = 24 } ), ( Color.yellow, { x = 35, y = 35 } ), ( Color.red, { x = 31, y = 31 } ) ]
                , headDrawing = [ ( Color.red, { x = 31, y = 31 } ), ( Color.yellow, { x = 35, y = 35 } ), ( Color.orange, { x = 23, y = 24 } ), ( Color.green, { x = 20, y = 45 } ) ]
                }

            -- Yellow's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 21, y = 44 } ), ( Color.orange, { x = 24, y = 24 } ), ( Color.yellow, { x = 34, y = 34 } ) ]
                , headDrawing = [ ( Color.yellow, { x = 34, y = 34 } ), ( Color.orange, { x = 24, y = 24 } ), ( Color.green, { x = 21, y = 44 } ) ]
                }

            -- Only Orange and Green left:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 22, y = 43 } ), ( Color.orange, { x = 25, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 25, y = 24 } ), ( Color.green, { x = 22, y = 43 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 26, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 26, y = 24 } ), ( Color.green, { x = 22, y = 43 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 23, y = 42 } ), ( Color.orange, { x = 27, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 27, y = 24 } ), ( Color.green, { x = 23, y = 42 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 24, y = 41 } ), ( Color.orange, { x = 28, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 28, y = 24 } ), ( Color.green, { x = 24, y = 41 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 29, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 29, y = 24 } ), ( Color.green, { x = 24, y = 41 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 25, y = 40 } ), ( Color.orange, { x = 30, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 30, y = 24 } ), ( Color.green, { x = 25, y = 40 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 26, y = 39 } ), ( Color.orange, { x = 31, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 31, y = 24 } ), ( Color.green, { x = 26, y = 39 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 32, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 32, y = 24 } ), ( Color.green, { x = 26, y = 39 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 27, y = 38 } ), ( Color.orange, { x = 33, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 33, y = 24 } ), ( Color.green, { x = 27, y = 38 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 28, y = 37 } ), ( Color.orange, { x = 34, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 34, y = 24 } ), ( Color.green, { x = 28, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 29, y = 36 } ), ( Color.orange, { x = 35, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 35, y = 24 } ), ( Color.green, { x = 29, y = 36 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 36, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 36, y = 24 } ), ( Color.green, { x = 29, y = 36 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 30, y = 35 } ), ( Color.orange, { x = 37, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 37, y = 24 } ), ( Color.green, { x = 30, y = 35 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 31, y = 34 } ), ( Color.orange, { x = 38, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 38, y = 24 } ), ( Color.green, { x = 31, y = 34 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 39, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 39, y = 24 } ), ( Color.green, { x = 31, y = 34 } ) ]
                }

            -- Green starts painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 32, y = 33 } ), ( Color.orange, { x = 40, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 40, y = 24 } ), ( Color.green, { x = 32, y = 33 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 33, y = 32 } ), ( Color.orange, { x = 41, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 41, y = 24 } ), ( Color.green, { x = 33, y = 32 } ) ]
                }

            -- Green stops painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 34, y = 31 } ), ( Color.orange, { x = 42, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 42, y = 24 } ), ( Color.green, { x = 34, y = 31 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 43, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 43, y = 24 } ), ( Color.green, { x = 34, y = 31 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 35, y = 30 } ), ( Color.orange, { x = 44, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 44, y = 24 } ), ( Color.green, { x = 35, y = 30 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 36, y = 29 } ), ( Color.orange, { x = 45, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 45, y = 24 } ), ( Color.green, { x = 36, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 46, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 46, y = 24 } ), ( Color.green, { x = 36, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 37, y = 28 } ), ( Color.orange, { x = 47, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 47, y = 24 } ), ( Color.green, { x = 37, y = 28 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { x = 38, y = 27 } ), ( Color.orange, { x = 48, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 48, y = 24 } ), ( Color.green, { x = 38, y = 27 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.orange, { x = 49, y = 24 } ) ]
                , headDrawing = [ ( Color.orange, { x = 49, y = 24 } ) ]
                }
            ]
    }
