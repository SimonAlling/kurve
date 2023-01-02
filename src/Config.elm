module Config exposing (Config, HoleConfig, KurveConfig, Player, SpawnConfig, WorldConfig, default, players)

import Color exposing (Color)
import Input exposing (Button(..))
import Types.Distance exposing (Distance(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


default : Config
default =
    { kurves =
        { tickrate = Tickrate 60
        , turningRadius = Radius 28.5
        , speed = Speed 60
        , thickness = Thickness 3
        , holes =
            { minInterval = Distance 90
            , maxInterval = Distance 300
            , minSize = Distance 5
            , maxSize = Distance 9
            }
        }
    , spawn =
        { margin = 100 -- The minimum distance from the wall that a Kurve can spawn.
        , desiredMinimumDistanceTurningRadiusFactor = 1
        , protectionAudacity = 0.25 -- Closer to 1 ⇔ less risk of spawn kills but higher risk of no solution
        , flickerTicksPerSecond = 20 -- At each tick, the spawning Kurve is toggled between visible and invisible.
        , numberOfFlickerTicks = 5
        , angleInterval = ( -pi / 2, pi / 2 )
        }
    , world =
        { width = 559
        , height = 480
        }
    }


players : List Player
players =
    let
        rgb : Int -> Int -> Int -> Color
        rgb =
            Color.rgb255
    in
    [ { color = rgb 255 40 0
      , controls = ( [ Key "Digit1" ], [ Key "KeyQ" ] )
      }
    , { color = rgb 195 195 0
      , controls = ( [ Key "ControlLeft", Key "KeyZ" ], [ Key "AltLeft", Key "KeyX" ] )
      }
    , { color = rgb 255 121 0
      , controls = ( [ Key "KeyM" ], [ Key "Comma" ] )
      }
    , { color = rgb 0 203 0
      , controls = ( [ Key "ArrowLeft" ], [ Key "ArrowDown" ] )
      }
    , { color = rgb 223 81 182
      , controls = ( [ Key "NumpadDivide", Key "End", Key "PageDown" ], [ Key "NumpadMultiply", Key "PageUp" ] )
      }
    , { color = rgb 0 162 203
      , controls = ( [ Mouse 0 ], [ Mouse 2 ] )
      }
    ]


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    }


type alias KurveConfig =
    { tickrate : Tickrate
    , speed : Speed
    , turningRadius : Radius
    , thickness : Thickness
    , holes : HoleConfig
    }


type alias SpawnConfig =
    { margin : Float
    , desiredMinimumDistanceTurningRadiusFactor : Float
    , protectionAudacity : Float
    , flickerTicksPerSecond : Float
    , numberOfFlickerTicks : Int
    , angleInterval : ( Float, Float )
    }


type alias WorldConfig =
    { width : Int
    , height : Int
    }


type alias Player =
    { color : Color
    , controls : ( List Button, List Button )
    }


type alias HoleConfig =
    { minInterval : Distance
    , maxInterval : Distance
    , minSize : Distance
    , maxSize : Distance
    }
