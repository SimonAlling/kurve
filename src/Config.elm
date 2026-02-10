module Config exposing
    ( Config
    , HoleConfig
    , KurveConfig
    , ReplayConfig
    , SpawnConfig
    , WorldConfig
    , default
    , withHardcodedHoles
    , withSpeed
    )

import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Tickrate exposing (Tickrate(..))


default : Config
default =
    { kurves =
        { tickrate = Tickrate 60
        , turningRadius = Radius 28.5
        , speed = Speed 60
        , holes =
            { minSolidTicks = 90
            , maxSolidTicks = 300
            , minHolyTicks = 7
            , maxHolyTicks = 11
            }
        }
    , spawn =
        { margin = 100 -- The minimum distance from the wall that a Kurve can spawn.
        , desiredMinimumDistanceTurningRadiusFactor = 1
        , protectionAudacity = 0.25 -- Closer to 1 ⇔ less risk of spawn kills but higher risk of no solution
        , flickerFrequency = 10 -- How many times per second the spawning Kurve performs a full cycle of being visible and then invisible.
        , numberOfFlickers = 8
        , angleInterval = ( 0, pi )
        }
    , world =
        { width = 559
        , height = 480
        }
    , replay =
        { skipStepInMs = 5000
        }
    }


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    , replay : ReplayConfig
    }


type alias KurveConfig =
    { tickrate : Tickrate
    , speed : Speed
    , turningRadius : Radius
    , holes : HoleConfig
    }


type alias SpawnConfig =
    { margin : Float
    , desiredMinimumDistanceTurningRadiusFactor : Float
    , protectionAudacity : Float
    , flickerFrequency : Float
    , numberOfFlickers : Int
    , angleInterval : ( Float, Float )
    }


type alias WorldConfig =
    { width : Int
    , height : Int
    }


type alias ReplayConfig =
    { skipStepInMs : Int
    }


type alias HoleConfig =
    { minSolidTicks : Int
    , maxSolidTicks : Int
    , minHolyTicks : Int
    , maxHolyTicks : Int
    }


withSpeed : Speed -> Config -> Config
withSpeed speed config =
    let
        kurveConfig : KurveConfig
        kurveConfig =
            config.kurves
    in
    { config
        | kurves =
            { kurveConfig
                | speed = speed
            }
    }


withHardcodedHoles : Int -> Int -> Config -> Config
withHardcodedHoles solidTicks holyTicks config =
    let
        defaultKurveConfig : KurveConfig
        defaultKurveConfig =
            config.kurves
    in
    { config
        | kurves =
            { defaultKurveConfig
                | holes =
                    { minSolidTicks = solidTicks
                    , maxSolidTicks = solidTicks
                    , minHolyTicks = holyTicks
                    , maxHolyTicks = holyTicks
                    }
            }
    }
