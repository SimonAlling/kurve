module TestScenarios.CuttingCornersPerfectOverpainting exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, draw, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    Config.default


red : Kurve
red =
    makeZombieKurve
        { color = Colors.red
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
        { color = Colors.yellow
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
        { color = Colors.orange
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
        { color = Colors.green
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
                , headDrawing = [ draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟩' ( 18, 47 ), draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟩' ( 18, 47 ), draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ draw '🟩' ( 18, 47 ), draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                }

            -- Spawns are drawn permanently:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 18, 47 ), draw '🟧' ( 20, 24 ), draw '🟨' ( 37, 37 ), draw '🟥' ( 29, 29 ) ]
                , headDrawing = []
                }

            -- The Kurves start moving:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 19, 46 ), draw '🟧' ( 21, 24 ), draw '🟨' ( 36, 36 ), draw '🟥' ( 30, 30 ) ]
                , headDrawing = [ draw '🟥' ( 30, 30 ), draw '🟨' ( 36, 36 ), draw '🟧' ( 21, 24 ), draw '🟩' ( 19, 46 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 22, 24 ) ]
                , headDrawing = [ draw '🟥' ( 30, 30 ), draw '🟨' ( 36, 36 ), draw '🟧' ( 22, 24 ), draw '🟩' ( 19, 46 ) ]
                }

            -- Red's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 20, 45 ), draw '🟧' ( 23, 24 ), draw '🟨' ( 35, 35 ), draw '🟥' ( 31, 31 ) ]
                , headDrawing = [ draw '🟥' ( 31, 31 ), draw '🟨' ( 35, 35 ), draw '🟧' ( 23, 24 ), draw '🟩' ( 20, 45 ) ]
                }

            -- Yellow's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 21, 44 ), draw '🟧' ( 24, 24 ), draw '🟨' ( 34, 34 ) ]
                , headDrawing = [ draw '🟨' ( 34, 34 ), draw '🟧' ( 24, 24 ), draw '🟩' ( 21, 44 ) ]
                }

            -- Only Orange and Green left:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 22, 43 ), draw '🟧' ( 25, 24 ) ]
                , headDrawing = [ draw '🟧' ( 25, 24 ), draw '🟩' ( 22, 43 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 26, 24 ) ]
                , headDrawing = [ draw '🟧' ( 26, 24 ), draw '🟩' ( 22, 43 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 23, 42 ), draw '🟧' ( 27, 24 ) ]
                , headDrawing = [ draw '🟧' ( 27, 24 ), draw '🟩' ( 23, 42 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 24, 41 ), draw '🟧' ( 28, 24 ) ]
                , headDrawing = [ draw '🟧' ( 28, 24 ), draw '🟩' ( 24, 41 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 29, 24 ) ]
                , headDrawing = [ draw '🟧' ( 29, 24 ), draw '🟩' ( 24, 41 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 25, 40 ), draw '🟧' ( 30, 24 ) ]
                , headDrawing = [ draw '🟧' ( 30, 24 ), draw '🟩' ( 25, 40 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 26, 39 ), draw '🟧' ( 31, 24 ) ]
                , headDrawing = [ draw '🟧' ( 31, 24 ), draw '🟩' ( 26, 39 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 32, 24 ) ]
                , headDrawing = [ draw '🟧' ( 32, 24 ), draw '🟩' ( 26, 39 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 27, 38 ), draw '🟧' ( 33, 24 ) ]
                , headDrawing = [ draw '🟧' ( 33, 24 ), draw '🟩' ( 27, 38 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 28, 37 ), draw '🟧' ( 34, 24 ) ]
                , headDrawing = [ draw '🟧' ( 34, 24 ), draw '🟩' ( 28, 37 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 29, 36 ), draw '🟧' ( 35, 24 ) ]
                , headDrawing = [ draw '🟧' ( 35, 24 ), draw '🟩' ( 29, 36 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 36, 24 ) ]
                , headDrawing = [ draw '🟧' ( 36, 24 ), draw '🟩' ( 29, 36 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 30, 35 ), draw '🟧' ( 37, 24 ) ]
                , headDrawing = [ draw '🟧' ( 37, 24 ), draw '🟩' ( 30, 35 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 31, 34 ), draw '🟧' ( 38, 24 ) ]
                , headDrawing = [ draw '🟧' ( 38, 24 ), draw '🟩' ( 31, 34 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 39, 24 ) ]
                , headDrawing = [ draw '🟧' ( 39, 24 ), draw '🟩' ( 31, 34 ) ]
                }

            -- Green starts painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 32, 33 ), draw '🟧' ( 40, 24 ) ]
                , headDrawing = [ draw '🟧' ( 40, 24 ), draw '🟩' ( 32, 33 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 33, 32 ), draw '🟧' ( 41, 24 ) ]
                , headDrawing = [ draw '🟧' ( 41, 24 ), draw '🟩' ( 33, 32 ) ]
                }

            -- Green stops painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 34, 31 ), draw '🟧' ( 42, 24 ) ]
                , headDrawing = [ draw '🟧' ( 42, 24 ), draw '🟩' ( 34, 31 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 43, 24 ) ]
                , headDrawing = [ draw '🟧' ( 43, 24 ), draw '🟩' ( 34, 31 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 35, 30 ), draw '🟧' ( 44, 24 ) ]
                , headDrawing = [ draw '🟧' ( 44, 24 ), draw '🟩' ( 35, 30 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 36, 29 ), draw '🟧' ( 45, 24 ) ]
                , headDrawing = [ draw '🟧' ( 45, 24 ), draw '🟩' ( 36, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 46, 24 ) ]
                , headDrawing = [ draw '🟧' ( 46, 24 ), draw '🟩' ( 36, 29 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 37, 28 ), draw '🟧' ( 47, 24 ) ]
                , headDrawing = [ draw '🟧' ( 47, 24 ), draw '🟩' ( 37, 28 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟩' ( 38, 27 ), draw '🟧' ( 48, 24 ) ]
                , headDrawing = [ draw '🟧' ( 48, 24 ), draw '🟩' ( 38, 27 ) ]
                }
            , DrawSomething
                { bodyDrawing = [ draw '🟧' ( 49, 24 ) ]
                , headDrawing = [ draw '🟧' ( 49, 24 ) ]
                }
            ]
    }
